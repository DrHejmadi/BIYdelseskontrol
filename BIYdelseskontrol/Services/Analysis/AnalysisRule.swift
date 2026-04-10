import Foundation

/// Lookup table: [CPR: [DateString: [ydelseskode]]]
typealias BillingLookup = [String: [String: Set<Int>]]

/// Build lookup for fast CPR+Date → ydelseskoder access
func buildBillingLookup(_ billings: [BillingRecord]) -> BillingLookup {
    var lookup = BillingLookup()
    for b in billings {
        lookup[b.cprnr, default: [:]][b.ydelsesdatoStr, default: []].insert(b.ydelseskode)
    }
    return lookup
}

/// Protocol all analysis rules conform to
protocol AnalysisRule: Sendable {
    var category: AnalysisCategory { get }

    func analyze(
        bookings: [BookingRecord],
        billingLookup: BillingLookup,
        notes: [NoteRecord],
        progress: @Sendable (Int, Int) -> Void  // (processed, found)
    ) -> [AnalysisFinding]
}
