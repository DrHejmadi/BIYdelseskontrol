import Foundation

struct ForkertYdelseRule: AnalysisRule {
    let category = AnalysisCategory.forkertGrundydelse

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
            let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []

            switch booking.bookingType {
            case .video:
                // Video should be 125
                if codes.contains(105) && !codes.contains(125) {
                    findings.append(makeFinding(booking: booking, codes: codes,
                        expected: "0125 (video, 163,18 kr)",
                        actual: "0105 (e-kons, 51,12 kr)",
                        problem: "Video afregnet som e-konsultation",
                        loss: 163.18 - 51.12))
                } else if codes.contains(201) && !codes.contains(125) {
                    findings.append(makeFinding(booking: booking, codes: codes,
                        expected: "0125 (video, 163,18 kr)",
                        actual: "0201 (telefon, 31,84 kr)",
                        problem: "Video afregnet som telefon",
                        loss: 163.18 - 31.84))
                } else if !codes.contains(125) && !codes.contains(101) && !codes.contains(105) && !codes.contains(201) {
                    findings.append(makeFinding(booking: booking, codes: codes,
                        expected: "0125 (video, 163,18 kr)",
                        actual: "Ingen grundydelse",
                        problem: "Video uden nogen grundydelse",
                        loss: 163.18))
                }

            case .fremmoede:
                // Fremmøde should be 101 (konsultation), not 105 (e-kons)
                if codes.contains(105) && !codes.contains(101) && !codes.contains(125) {
                    findings.append(makeFinding(booking: booking, codes: codes,
                        expected: "0101 (konsultation, 172,88 kr)",
                        actual: "0105 (e-kons, 51,12 kr)",
                        problem: "Fremmøde afregnet som e-konsultation",
                        loss: 172.88 - 51.12))
                }

            default:
                break
            }

            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }

    private func makeFinding(booking: BookingRecord, codes: Set<Int>,
                             expected: String, actual: String,
                             problem: String, loss: Double) -> AnalysisFinding {
        AnalysisFinding(
            category: category,
            cpr: booking.cpr,
            navn: booking.navn,
            dato: booking.dato,
            datoStr: booking.datoStr,
            bookingEmne: booking.emneAarsag,
            expectedYdelse: expected,
            actualYdelse: actual,
            laege: booking.laege,
            problem: problem,
            estimatedLoss: loss
        )
    }
}
