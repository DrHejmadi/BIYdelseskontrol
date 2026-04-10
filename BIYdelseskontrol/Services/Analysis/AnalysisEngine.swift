import Foundation

/// Main analysis orchestrator
actor AnalysisEngine {
    private let rules: [any AnalysisRule] = [
        CRPRule(),
        UVIRule(),
        SamtaleterapiRule(),
        BesoegRule(),
        ForkertYdelseRule(),
        SygeplejerOpkaldRule(),
        NotaterUdenYdelseRule(),
        EKGLFURule()
    ]

    struct Progress: Sendable {
        let category: AnalysisCategory
        let recordsProcessed: Int
        let findingsCount: Int
        let isComplete: Bool
    }

    func runAllAnalyses(
        bookings: [BookingRecord],
        billings: [BillingRecord],
        notes: [NoteRecord],
        onProgress: @Sendable @escaping (Progress) -> Void
    ) async -> [AnalysisResult] {
        // Build lookup once
        let billingLookup = buildBillingLookup(billings)
        var results: [AnalysisResult] = []

        for rule in rules {
            // Skip notater rule if no notes loaded
            if rule.category == .notaterUdenYdelse && notes.isEmpty { continue }
            // Skip booking rules if no bookings loaded
            if rule.category != .notaterUdenYdelse && bookings.isEmpty { continue }

            let totalRecords = rule.category == .notaterUdenYdelse ? notes.count : bookings.count

            let findings = rule.analyze(
                bookings: bookings,
                billingLookup: billingLookup,
                notes: notes
            ) { processed, found in
                onProgress(Progress(
                    category: rule.category,
                    recordsProcessed: processed,
                    findingsCount: found,
                    isComplete: false
                ))
            }

            let result = AnalysisResult(
                category: rule.category,
                findings: findings,
                totalRecordsScanned: totalRecords
            )
            results.append(result)

            onProgress(Progress(
                category: rule.category,
                recordsProcessed: totalRecords,
                findingsCount: findings.count,
                isComplete: true
            ))
        }

        return results
    }
}
