import Foundation

struct UVIRule: AnalysisRule {
    let category = AnalysisCategory.manglendeUVI

    private let uviKeywords = ["uvi", "urinvejsinfektion", "blærebetændelse", "cystit", "dysuri"]

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
            let isUVI = uviKeywords.contains { lower.contains($0) }

            if isUVI {
                let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []
                let har2101 = codes.contains(2101)
                let har2133 = codes.contains(2133)
                let har7122 = codes.contains(7122)

                if !har2101 || !har2133 || !har7122 {
                    var missing: [String] = []
                    if !har2101 { missing.append("2101 (blodtagning)") }
                    if !har2133 { missing.append("2133 (forsendelse)") }
                    if !har7122 { missing.append("7122 (mikroskopi urin)") }

                    let loss = (!har2101 ? 55.72 : 0) + (!har2133 ? 39.82 : 0) + (!har7122 ? 60.75 : 0)

                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: booking.cpr,
                        navn: booking.navn,
                        dato: booking.dato,
                        datoStr: booking.datoStr,
                        bookingEmne: booking.emneAarsag,
                        expectedYdelse: "2101 + 2133 + 7122",
                        actualYdelse: "Mangler: \(missing.joined(separator: ", "))",
                        laege: booking.laege,
                        problem: "UVI uden fuld prøvepakke",
                        estimatedLoss: loss
                    ))
                }
            }
            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }
}
