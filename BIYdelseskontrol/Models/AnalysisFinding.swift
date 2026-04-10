import Foundation

struct AnalysisFinding: Identifiable, Sendable {
    let id = UUID()
    let category: AnalysisCategory
    let cpr: String
    let navn: String
    let dato: Date
    let datoStr: String
    let bookingEmne: String
    let expectedYdelse: String
    let actualYdelse: String
    let laege: String
    let problem: String
    let estimatedLoss: Double

    // LLM-enriched properties (optional)
    var llmExplanation: String?
    var llmConfirmed: Bool?
}

struct AnalysisResult: Sendable {
    let category: AnalysisCategory
    let findings: [AnalysisFinding]
    let totalRecordsScanned: Int

    var totalEstimatedLoss: Double {
        findings.reduce(0) { $0 + $1.estimatedLoss }
    }

    var findingsCount: Int { findings.count }
}
