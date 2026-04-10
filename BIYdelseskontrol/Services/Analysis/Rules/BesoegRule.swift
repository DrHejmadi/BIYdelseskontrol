import Foundation

struct BesoegRule: AnalysisRule {
    let category = AnalysisCategory.manglendeBesoeg

    private let besoegYdelser: Set<Int> = [111, 112, 113, 114, 115, 116, 117, 118, 119]

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

            if booking.bookingType == .besoeg {
                let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []
                let harBesoeg = !codes.isDisjoint(with: besoegYdelser)

                if !harBesoeg {
                    findings.append(AnalysisFinding(
                        category: category,
                        cpr: booking.cpr,
                        navn: booking.navn,
                        dato: booking.dato,
                        datoStr: booking.datoStr,
                        bookingEmne: booking.emneAarsag,
                        expectedYdelse: "Besøgsydelse (0111-0119)",
                        actualYdelse: codes.isEmpty ? "Ingen" : codes.sorted().map(String.init).joined(separator: ", "),
                        laege: booking.laege,
                        problem: "Besøg uden besøgsydelse",
                        estimatedLoss: 175.0
                    ))
                }
            }
            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }
}
