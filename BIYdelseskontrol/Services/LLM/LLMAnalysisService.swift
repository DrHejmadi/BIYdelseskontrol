import Foundation

actor LLMAnalysisService {
    private let ollama = OllamaService.shared

    private let systemPrompt = """
    Du er en dansk almen praksis-assistent der kontrollerer ydelsesregistrering.
    Du kender PLO-overenskomsten (OK24/OK26) og alle ydelseskoder.

    YDELSESKODER:
    - 0101 (konsultation, 172,88 kr): Fysisk fremmoede
    - 0105 (e-konsultation, 51,12 kr): Skriftlig kontakt via MinLaege/mail
    - 0120 (aarsstatus, 437,77 kr): Aarlig helbredsundersoegelse
    - 0124 (laegefaglig vurdering, 175,71 kr): Vurdering uden patientkontakt
    - 0125 (videokonsultation, 163,18 kr): Video-samtale
    - 0201 (telefonkonsultation, 31,84 kr): Kort telefonisk kontakt
    - 0204 (aftalt telefon, 130,10 kr): Planlagt telefonsamtale
    - 2101 (blodtagning, 55,72 kr): Blodproeve-tagning
    - 2133 (forsendelse, 39,82 kr): Forsendelse af proeve
    - 4609/4610 (samtaleterapi, 454,66 kr): Krise/psykterapi >= 20 min
    - 7120 (CRP, 75,93 kr): CRP-maaling
    - 7122 (mikroskopi urin, 60,75 kr): Urinmikroskopi

    REGLER:
    - Patient-initierede mails (via MinLaege) kan IKKE udloese ydelse
    - Telefonisk kontakt under 5 min = 0201
    - Aftalt telefonkonsultation = 0204
    - CRP boer tages ved luftvejssymptomer (hoste, feber, ondt i halsen)
    - Ved UVI: blodtagning + forsendelse + urinmikroskopi

    Svar KUN med valid JSON. Intet andet.
    """

    struct LLMFinding: Decodable {
        let confirmed: Bool
        let explanation: String
        let suggestedYdelse: String?
        let confidence: Double?
    }

    struct LLMResponse: Decodable {
        let findings: [LLMNewFinding]?
        let confirmation: LLMFinding?
    }

    struct LLMNewFinding: Decodable {
        let type: String
        let explanation: String
        let suggestedYdelse: String
        let estimatedLoss: Double?
    }

    /// Verify an existing rule-based finding with LLM
    func verifyFinding(_ finding: AnalysisFinding, model: String) async throws -> (confirmed: Bool, explanation: String) {
        let prompt = """
        Bekraeft eller afvis dette fund:

        Kategori: \(finding.category.rawValue)
        Booking/notat: \(finding.bookingEmne)
        Registrerede ydelser: \(finding.actualYdelse)
        Forventet ydelse: \(finding.expectedYdelse)
        Problem: \(finding.problem)

        Svar i JSON: {"confirmed": true/false, "explanation": "kort dansk begrundelse"}
        """

        let response = try await ollama.generate(model: model, system: systemPrompt, prompt: prompt)

        if let data = response.data(using: .utf8),
           let json = try? JSONDecoder().decode(LLMFinding.self, from: data) {
            return (json.confirmed, json.explanation)
        }

        // Fallback: parse as text
        let confirmed = !response.lowercased().contains("afvis")
        return (confirmed, response.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Scan notes for findings that rules might have missed
    func scanNote(noteText: String, emne: String, existingCodes: Set<Int>, model: String) async throws -> [LLMNewFinding] {
        let codesStr = existingCodes.isEmpty ? "Ingen" : existingCodes.sorted().map(String.init).joined(separator: ", ")

        let prompt = """
        Analyser dette journalnotat og vurder om der mangler ydelser:

        Emne: \(emne)
        Notat: \(noteText.prefix(500))
        Eksisterende ydelser: \(codesStr)

        Svar i JSON: {"findings": [{"type": "manglende_ydelse", "explanation": "begrundelse", "suggestedYdelse": "kode", "estimatedLoss": 0.0}]}
        Svar {"findings": []} hvis alt ser korrekt ud.
        """

        let response = try await ollama.generate(model: model, system: systemPrompt, prompt: prompt)

        if let data = response.data(using: .utf8),
           let json = try? JSONDecoder().decode(LLMResponse.self, from: data),
           let findings = json.findings {
            return findings
        }

        return []
    }
}
