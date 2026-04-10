import Foundation

struct NotaterUdenYdelseRule: AnalysisRule {
    let category = AnalysisCategory.notaterUdenYdelse

    // Keywords indicating call with parent/guardian about a child (3. person → 0101)
    private let forældreKeywords = [
        "forælder", "forældre", "mor ringer", "far ringer", "moderen", "faderen",
        "mors henvendelse", "fars henvendelse", "pårørende ringer", "ringer vedr barn",
        "ringer om barn", "vedr. barn", "vedr barn", "ang. barn", "ang barn",
        "barnets mor", "barnets far", "forældr"
    ]

    // Keywords indicating call with home nursing (hjemmesygeplejen → 0124)
    private let hjemmesygeplejKeywords = [
        "hjemmesygepl", "hjemmepl", "hjemmesyg", "plejecenter", "plejehjem",
        "sygeplejerske ringer", "spl ringer", "spl. ringer", "kommunal sygepl",
        "hjemmehjælp", "plejen ringer", "visitator"
    ]

    // Keywords indicating conference (konference → 0201/0204 or 0101 if pt present)
    private let konferenceKeywords = [
        "konf ", "konf.", "konference", "tværfaglig", "netværksmøde",
        "samarbejdsmøde", "statusmøde"
    ]

    // Keywords indicating patient was present at conference → 0101
    private let patientTilstedeKeywords = [
        "pt tilstede", "pt. tilstede", "patienten tilstede",
        "patienten deltog", "pt deltog", "pt. deltog",
        "patient deltager", "pt mødt", "pt. mødt"
    ]

    // Keywords indicating visit/besøg
    private let besoegKeywords = [
        "hjemmebesøg", "besøg hos", "sygebesøg", "besøgt patient",
        "besøgt pt", "besøg i hjemmet", "kørt ud til"
    ]

    // Keywords for e-konsultation / 0127 triggers from conference
    private let eKonsKonferenceKeywords = [
        "kommunal korrespondance", "korrespondance", "kommunen skriver",
        "skrevet til kommune", "elektronisk kommunikation"
    ]

    // Pure prescription renewal — NO billing per overenskomst
    private let receptFornyelseMønstre = [
        "receptfornyelse", "rp fornyelse", "rp. fornyelse",
        "ren recept", "fornyet recept", "genbestilling af medicin",
        "fornyet rp", "medicinfornyelse", "forny recept"
    ]

    // General clinical patterns
    private let clinicalPatterns: [(pattern: String, expectedYdelse: String, loss: Double)] = [
        ("tlf", "0201 (telefonkonsultation)", 31.84),
        ("tk ", "0201 (telefonkonsultation)", 31.84),
        ("telefonisk", "0201 (telefonkonsultation)", 31.84),
        ("ringet", "0201 (telefonkonsultation)", 31.84),
        ("talt med", "0201 (telefonkonsultation)", 31.84),
        ("henvist", "0105 (e-konsultation)", 51.12),
        ("henvisning", "0105 (e-konsultation)", 51.12),
        ("svar på", "0201 (telefonkonsultation)", 31.84),
        ("prøvesvar", "0201 (telefonkonsultation)", 31.84),
        ("årskontrol", "0120 (årsstatus)", 437.77),
        ("åk ", "0120 (årsstatus)", 437.77),
        ("vurdering", "0105 (e-konsultation)", 51.12),
    ]

    func analyze(
        bookings: [BookingRecord],
        billingLookup: BillingLookup,
        notes: [NoteRecord],
        progress: @Sendable (Int, Int) -> Void
    ) -> [AnalysisFinding] {
        var findings: [AnalysisFinding] = []
        var processed = 0

        for note in notes {
            processed += 1

            // Skip patient-initiated notes (per overenskomst)
            if note.erPatientInitieret { continue }

            // Check if any billing exists for this CPR+date
            let cprNormalized = note.cpr.replacingOccurrences(of: "-", with: "")
            let codes = billingLookup[cprNormalized]?[note.datoStr] ?? []
            if !codes.isEmpty { continue } // Already has billing, skip

            let lower = note.notat.lowercased()
            let emneLower = note.emne.lowercased()

            // === EXCLUSION: Ren receptfornyelse giver IKKE ydelse ===
            if receptFornyelseMønstre.contains(where: { lower.contains($0) }) {
                // Check it's ONLY a prescription renewal, not combined with other clinical work
                let hasOtherClinical = clinicalPatterns.contains { lower.contains($0.pattern) && $0.pattern != "rp." && $0.pattern != "recept" }
                if !hasOtherClinical { continue }
            }
            // Also skip if note is just "rp." or "recept" with no other clinical content
            if (lower.hasPrefix("rp.") || lower.hasPrefix("rp ") || lower == "recept") && lower.count < 30 {
                continue
            }

            // === RULE 1: TK med forældre om barn → 0101 (konsultation ved 3. person) ===
            if forældreKeywords.contains(where: { lower.contains($0) }) {
                findings.append(AnalysisFinding(
                    category: category,
                    cpr: note.cpr,
                    navn: "\(note.fornavn) \(note.efternavn)",
                    dato: note.dato,
                    datoStr: note.datoStr,
                    bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                    expectedYdelse: "0101 (konsultation v/ 3. person)",
                    actualYdelse: "Ingen ydelse registreret",
                    laege: "",
                    problem: "TK med forælder/pårørende om patient — konsultation v/ 3. person",
                    estimatedLoss: 172.88
                ))
                continue
            }

            // === RULE 2: TK med hjemmesygeplejen → 0124 (lægefaglig vurdering) ===
            if hjemmesygeplejKeywords.contains(where: { lower.contains($0) }) {
                // Check if it's a written e-konsultation → 0127
                if eKonsKonferenceKeywords.contains(where: { lower.contains($0) }) {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: note.cpr,
                        navn: "\(note.fornavn) \(note.efternavn)",
                        dato: note.dato,
                        datoStr: note.datoStr,
                        bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                        expectedYdelse: "0127 (e-kons med kommune)",
                        actualYdelse: "Ingen ydelse registreret",
                        laege: "",
                        problem: "Skriftlig kommunikation med hjemmesygeplejen — 0127",
                        estimatedLoss: 51.12
                    ))
                } else {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: note.cpr,
                        navn: "\(note.fornavn) \(note.efternavn)",
                        dato: note.dato,
                        datoStr: note.datoStr,
                        bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                        expectedYdelse: "0124 (lægefaglig vurdering)",
                        actualYdelse: "Ingen ydelse registreret",
                        laege: "",
                        problem: "TK med hjemmesygeplejen — lægefaglig vurdering",
                        estimatedLoss: 175.71
                    ))
                }
                continue
            }

            // === RULE 3: Konference ===
            if konferenceKeywords.contains(where: { lower.contains($0) }) {
                if patientTilstedeKeywords.contains(where: { lower.contains($0) }) {
                    // Patient tilstede ved konference → 0101
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: note.cpr,
                        navn: "\(note.fornavn) \(note.efternavn)",
                        dato: note.dato,
                        datoStr: note.datoStr,
                        bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                        expectedYdelse: "0101 (konsultation — pt tilstede ved konf)",
                        actualYdelse: "Ingen ydelse registreret",
                        laege: "",
                        problem: "Konference med patient tilstede — konsultation",
                        estimatedLoss: 172.88
                    ))
                } else if eKonsKonferenceKeywords.contains(where: { lower.contains($0) }) {
                    // Konference med skriftlig kommunikation → 0127/0105
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: note.cpr,
                        navn: "\(note.fornavn) \(note.efternavn)",
                        dato: note.dato,
                        datoStr: note.datoStr,
                        bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                        expectedYdelse: "0127/0105 (e-kons fra konference)",
                        actualYdelse: "Ingen ydelse registreret",
                        laege: "",
                        problem: "Konference med skriftlig opfølgning — e-konsultation",
                        estimatedLoss: 51.12
                    ))
                } else {
                    // Konference telefonisk → 0201/0204
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: note.cpr,
                        navn: "\(note.fornavn) \(note.efternavn)",
                        dato: note.dato,
                        datoStr: note.datoStr,
                        bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                        expectedYdelse: "0201/0204 (TK/aftalt TK fra konference)",
                        actualYdelse: "Ingen ydelse registreret",
                        laege: "",
                        problem: "Konference uden ydelse — TK eller aftalt TK",
                        estimatedLoss: 130.10
                    ))
                }
                continue
            }

            // === RULE 4: Besøg uden afregning ===
            if besoegKeywords.contains(where: { lower.contains($0) }) {
                findings.append(AnalysisFinding(
                    category: category,
                    cpr: note.cpr,
                    navn: "\(note.fornavn) \(note.efternavn)",
                    dato: note.dato,
                    datoStr: note.datoStr,
                    bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                    expectedYdelse: "Besøgsydelse (0111+)",
                    actualYdelse: "Ingen ydelse registreret",
                    laege: "",
                    problem: "Hjemmebesøg dokumenteret i notat uden besøgsydelse",
                    estimatedLoss: 175.0
                ))
                continue
            }

            // === RULE 5: Attester/Lægebreve → kun 0105/0127, IKKE attestydelse generelt ===
            if lower.contains("attest") || lower.contains("lægebrev") || lower.contains("lægeerklæring") {
                // Attester giver kun ydelse hvis det resulterer i e-konsultation
                findings.append(AnalysisFinding(
                    category: category,
                    cpr: note.cpr,
                    navn: "\(note.fornavn) \(note.efternavn)",
                    dato: note.dato,
                    datoStr: note.datoStr,
                    bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                    expectedYdelse: "0105/0127 (e-kons v/ attest)",
                    actualYdelse: "Ingen ydelse registreret",
                    laege: "",
                    problem: "Attest/lægebrev — kan udløse e-konsultation",
                    estimatedLoss: 51.12
                ))
                continue
            }

            // === RULE 6: Øvrige kliniske mønstre (generel catch) ===
            for cp in clinicalPatterns {
                if lower.contains(cp.pattern) {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: note.cpr,
                        navn: "\(note.fornavn) \(note.efternavn)",
                        dato: note.dato,
                        datoStr: note.datoStr,
                        bookingEmne: "[\(note.emne)] \(String(note.notat.prefix(80)))",
                        expectedYdelse: cp.expectedYdelse,
                        actualYdelse: "Ingen ydelse registreret",
                        laege: "",
                        problem: "Journalnotat med klinisk arbejde uden ydelse",
                        estimatedLoss: cp.loss
                    ))
                    break
                }
            }
            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }
}
