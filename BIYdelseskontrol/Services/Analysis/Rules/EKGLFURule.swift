import Foundation

struct EKGLFURule: AnalysisRule {
    let category = AnalysisCategory.manglendeEKGLFU

    // Keywords indicating EKG was planned
    private let ekgKeywords: [String] = [
        "ekg", "elektrokardiogra", "12-afledn", "hjertekardiogram"
    ]

    // Keywords indicating LFU/spirometri was planned
    private let lfuKeywords: [String] = [
        "lfu", "spirometr", "lungefunktion", "peak flow", "peakflow",
        "fev1", "fvc", "pef"
    ]

    // EKG ydelseskode
    private let ekgYdelse = 7113

    // Spirometri ydelseskode
    private let spirometriYdelse = 7121

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
            let codes = billingLookup[booking.cpr]?[booking.datoStr] ?? []

            let hasEKGKeyword = ekgKeywords.contains { lower.contains($0) }
            let hasLFUKeyword = lfuKeywords.contains { lower.contains($0) }

            let hasEKGYdelse = codes.contains(ekgYdelse)
            let hasLFUYdelse = codes.contains(spirometriYdelse)

            // Planlagt EKG men ikke afregnet
            if hasEKGKeyword && !hasEKGYdelse {
                findings.append(AnalysisFinding(
                    category: category,
                    cpr: booking.cpr,
                    navn: booking.navn,
                    dato: booking.dato,
                    datoStr: booking.datoStr,
                    bookingEmne: booking.emneAarsag,
                    expectedYdelse: "7113 (EKG)",
                    actualYdelse: codes.isEmpty ? "Ingen" : codes.sorted().map(String.init).joined(separator: ", "),
                    laege: booking.laege,
                    problem: "EKG planlagt i program men ikke afregnet",
                    estimatedLoss: 150.0
                ))
            }

            // Planlagt LFU/spirometri men ikke afregnet
            if hasLFUKeyword && !hasLFUYdelse {
                findings.append(AnalysisFinding(
                    category: category,
                    cpr: booking.cpr,
                    navn: booking.navn,
                    dato: booking.dato,
                    datoStr: booking.datoStr,
                    bookingEmne: booking.emneAarsag,
                    expectedYdelse: "7121 (spirometri/LFU)",
                    actualYdelse: codes.isEmpty ? "Ingen" : codes.sorted().map(String.init).joined(separator: ", "),
                    laege: booking.laege,
                    problem: "LFU/spirometri planlagt i program men ikke afregnet",
                    estimatedLoss: 150.0
                ))
            }

            if processed % 50 == 0 { progress(processed, findings.count) }
        }
        progress(processed, findings.count)
        return findings
    }
}
