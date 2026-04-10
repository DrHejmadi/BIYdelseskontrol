import Foundation

struct SygeplejerOpkaldRule: AnalysisRule {
    let category = AnalysisCategory.sygeplejerOpkald

    private let opkaldKeywords = [
        "sygepl ring", "sygepl. ring", "sygeplejerske ring",
        "ring retur", "tk svar", "svar på prøve",
        "sygepl svar", "sygepl. svar", "spl ring", "spl. ring"
    ]

    // Acceptable ydelser for these calls
    private let acceptableYdelser: Set<Int> = [124, 201, 204]

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
            let isSygeplejerOpkald = opkaldKeywords.contains { lower.contains($0) }

            if isSygeplejerOpkald {
                let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []
                let harAcceptabel = !codes.isDisjoint(with: acceptableYdelser)

                if !harAcceptabel {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: booking.cpr,
                        navn: booking.navn,
                        dato: booking.dato,
                        datoStr: booking.datoStr,
                        bookingEmne: booking.emneAarsag,
                        expectedYdelse: "0124/0201/0204",
                        actualYdelse: codes.isEmpty ? "Ingen" : codes.sorted().map(String.init).joined(separator: ", "),
                        laege: booking.laege,
                        problem: "Sygeplejerske-opkald uden ydelse",
                        estimatedLoss: 130.10
                    ))
                }
            }
            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }
}
