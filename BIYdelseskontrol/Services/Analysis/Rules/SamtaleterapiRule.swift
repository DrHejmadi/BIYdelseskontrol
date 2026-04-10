import Foundation

struct SamtaleterapiRule: AnalysisRule {
    let category = AnalysisCategory.manglendeSamtaleterapi

    private let samtaleKeywords = [
        "samtale", "krise", "psyk", "terapi", "angst", "depression",
        "stress", "sorg", "misbrug", "alkohol", "selvmord", "suicid",
        "anoreksi", "bulimi", "ptsd", "ocd", "panik", "fobi",
        "adhd", "add", "bipolar", "skizofreni"
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
            let isSamtale = samtaleKeywords.contains { lower.contains($0) }

            if isSamtale {
                let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []
                if !codes.contains(4609) && !codes.contains(4610) {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: booking.cpr,
                        navn: booking.navn,
                        dato: booking.dato,
                        datoStr: booking.datoStr,
                        bookingEmne: booking.emneAarsag,
                        expectedYdelse: "4609 eller 4610",
                        actualYdelse: codes.isEmpty ? "Ingen" : codes.sorted().map(String.init).joined(separator: ", "),
                        laege: booking.laege,
                        problem: "Samtale uden 4609/4610 (samtaleterapi)",
                        estimatedLoss: 454.66
                    ))
                }
            }
            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }
}
