import SwiftUI

enum AppTab: String, CaseIterable {
    case importData = "Import"
    case analysis = "Analyse"
    case results = "Resultater"
    case llm = "AI Motor"
    case gdpr = "GDPR"
}

@Observable
@MainActor
class AppViewModel {
    // MARK: - Init
    init() {
        self.llmEnabled = UserDefaults.standard.bool(forKey: "llmEnabled")
        self.llmModelName = UserDefaults.standard.string(forKey: "llmModelName") ?? "llama3.1:8b"
    }

    // MARK: - Navigation
    var currentTab: AppTab = .importData

    // MARK: - Import State
    var billingFileURL: URL?
    var bookingFileURL: URL?
    var notesFileURL: URL?

    var billingRecords: [BillingRecord] = []
    var bookingRecords: [BookingRecord] = []
    var noteRecords: [NoteRecord] = []

    var importError: String?
    var isImporting = false
    var importComplete = false

    // MARK: - Analysis State
    var isAnalyzing = false
    var analysisComplete = false
    var progressPerCategory: [AnalysisCategory: CategoryProgress] = [:]
    var currentCategory: AnalysisCategory?
    var results: [AnalysisResult] = []

    struct CategoryProgress {
        var recordsProcessed: Int = 0
        var findingsCount: Int = 0
        var isComplete: Bool = false
    }

    // MARK: - LLM State
    var llmEnabled: Bool {
        didSet { UserDefaults.standard.set(llmEnabled, forKey: "llmEnabled") }
    }
    var llmModelName: String {
        didSet { UserDefaults.standard.set(llmModelName, forKey: "llmModelName") }
    }
    var ollamaRunning = false
    var ollamaModels: [String] = []
    var llmProgress: String?
    var llmFindingsCount: Int = 0
    var isLLMAnalyzing = false

    // MARK: - Export
    var isExporting = false
    var exportSuccess = false
    var exportError: String?

    // MARK: - Computed
    var totalFindings: Int {
        results.reduce(0) { $0 + $1.findingsCount }
    }

    var totalEstimatedLoss: Double {
        results.reduce(0) { $0 + $1.totalEstimatedLoss }
    }

    var canStartAnalysis: Bool {
        !billingRecords.isEmpty && (!bookingRecords.isEmpty || !noteRecords.isEmpty)
    }

    // MARK: - Import Actions

    func importFile(_ url: URL, type: FileCategory) {
        isImporting = true
        importError = nil

        Task {
            do {
                // Start accessing security-scoped resource
                let didStart = url.startAccessingSecurityScopedResource()
                defer { if didStart { url.stopAccessingSecurityScopedResource() } }

                switch type {
                case .billing:
                    billingFileURL = url
                    billingRecords = try DataImportService.importBillingRecords(from: url)
                case .booking:
                    bookingFileURL = url
                    bookingRecords = try DataImportService.importBookingRecords(from: url)
                case .notes:
                    notesFileURL = url
                    noteRecords = try DataImportService.importNoteRecords(from: url)
                }

                importComplete = true
            } catch {
                importError = error.localizedDescription
            }
            isImporting = false
        }
    }

    enum FileCategory {
        case billing, booking, notes
    }

    // MARK: - Analysis Actions

    func startAnalysis() {
        guard canStartAnalysis else { return }
        isAnalyzing = true
        analysisComplete = false
        results = []
        progressPerCategory = [:]

        // Initialize progress for all categories
        for cat in AnalysisCategory.allCases {
            progressPerCategory[cat] = CategoryProgress()
        }

        Task.detached { [bookingRecords, billingRecords, noteRecords] in
            let engine = AnalysisEngine()
            let results = await engine.runAllAnalyses(
                bookings: bookingRecords,
                billings: billingRecords,
                notes: noteRecords
            ) { progress in
                Task { @MainActor [weak self] in
                    self?.progressPerCategory[progress.category] = CategoryProgress(
                        recordsProcessed: progress.recordsProcessed,
                        findingsCount: progress.findingsCount,
                        isComplete: progress.isComplete
                    )
                    self?.currentCategory = progress.category
                }
            }

            await MainActor.run { [weak self] in
                self?.results = results
                self?.isAnalyzing = false
                self?.analysisComplete = true
            }

            // Run optional LLM pass after rules complete
            await MainActor.run { [weak self] in
                guard let self else { return }
                Task {
                    await self.runLLMAnalysis()
                    self.currentTab = .results
                }
            }
        }
    }

    // MARK: - LLM Actions

    func checkOllama() async {
        let running = await OllamaService.shared.isRunning()
        ollamaRunning = running
        if running {
            do {
                ollamaModels = try await OllamaService.shared.availableModels()
                // If current model not in list and list is non-empty, select first
                if !ollamaModels.contains(llmModelName), let first = ollamaModels.first {
                    llmModelName = first
                }
            } catch {
                ollamaModels = []
            }
        } else {
            ollamaModels = []
        }
    }

    private func runLLMAnalysis() async {
        guard llmEnabled else { return }

        let running = await OllamaService.shared.isRunning()
        guard running else {
            llmProgress = "Ollama koerer ikke — AI-analyse sprunget over"
            return
        }

        isLLMAnalyzing = true
        llmProgress = "AI-analyse starter..."
        llmFindingsCount = 0

        let llmService = LLMAnalysisService()
        let model = llmModelName

        // Pass 1: Verify existing findings
        var updatedResults: [AnalysisResult] = []
        for result in results {
            var updatedFindings: [AnalysisFinding] = []
            for (index, finding) in result.findings.enumerated() {
                llmProgress = "Verificerer \(result.category.rawValue): \(index + 1)/\(result.findings.count)"
                var mutableFinding = finding
                do {
                    let (confirmed, explanation) = try await llmService.verifyFinding(finding, model: model)
                    mutableFinding.llmConfirmed = confirmed
                    mutableFinding.llmExplanation = explanation
                    llmFindingsCount += 1
                } catch {
                    // LLM error on single finding — skip silently
                    mutableFinding.llmExplanation = nil
                    mutableFinding.llmConfirmed = nil
                }
                updatedFindings.append(mutableFinding)
            }
            updatedResults.append(AnalysisResult(
                category: result.category,
                findings: updatedFindings,
                totalRecordsScanned: result.totalRecordsScanned
            ))
        }
        results = updatedResults

        llmProgress = "AI-analyse faerdig — \(llmFindingsCount) fund verificeret"
        isLLMAnalyzing = false
    }

    // MARK: - Export

    func exportResults() {
        let panel = NSSavePanel()
        panel.title = "Gem kontrolark"
        panel.nameFieldStringValue = "Ydelseskontrol.xlsx"
        panel.allowedContentTypes = [.init(filenameExtension: "xlsx")!]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        isExporting = true
        exportError = nil

        Task {
            do {
                try XLSXExporter.export(results: results, to: url)
                exportSuccess = true
            } catch {
                exportError = error.localizedDescription
            }
            isExporting = false
        }
    }
}
