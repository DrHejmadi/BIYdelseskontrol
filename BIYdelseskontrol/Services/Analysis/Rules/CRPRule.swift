import Foundation

struct CRPRule: AnalysisRule {
    let category = AnalysisCategory.manglendeCRP

    /// Broad respiratory keywords (Danish)
    private let respiratoryKeywords: [String] = [
        "hoste", "host", "feber", "forkølelse", "forkølel", "halsbetændelse",
        "øresmerter", "ørebetændelse", "pneumoni", "bronkitis", "influenza",
        "covid", "åndenød", "luftvej", "ondt i halsen", "bihulebetændelse",
        "forkølet", "snot", "slim", "ekspektora", "tonsil", "strep",
        "pharyngit", "sinusit", "otitis", "rhinit", "laryngit",
        "astma", "rs-virus", "rsv", "kighoste", "croup", "krupp",
        "lungebetændelse", "ørepine", "mellemøre"
    ]

    func analyze(
        bookings: [BookingRecord],
        billingLookup: BillingLookup,
        notes: [NoteRecord],
        progress: @Sendable (Int, Int) -> Void
    ) -> [AnalysisFinding] {
        var findings: [AnalysisFinding] = []
        var processed = 0

        for booking in bookings {
            processed += 1
            let lower = booking.emneAarsag.lowercased()
            let isRespiratory = respiratoryKeywords.contains { lower.contains($0) }

            if isRespiratory {
                let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []
                if !codes.contains(7120) {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: booking.cpr,
                        navn: booking.navn,
                        dato: booking.dato,
                        datoStr: booking.datoStr,
                        bookingEmne: booking.emneAarsag,
                        expectedYdelse: "7120 (CRP)",
                        actualYdelse: codes.isEmpty ? "Ingen" : codes.sorted().map(String.init).joined(separator: ", "),
                        laege: booking.laege,
                        problem: "Luftvejsinfektion uden CRP (7120)",
                        estimatedLoss: 75.93
                    ))
                }
            }

            if processed % 50 == 0 {
                progress(processed, findings.count)
            }
        }
        progress(processed, findings.count)
        return findings
    }
}
