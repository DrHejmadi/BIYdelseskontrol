import SwiftUI

struct AnalysisProgressView: View {
    @Bindable var vm: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if vm.isAnalyzing || vm.analysisComplete {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(AnalysisCategory.allCases) { category in
                            CategoryProgressCard(
                                category: category,
                                progress: vm.progressPerCategory[category],
                                isCurrent: vm.currentCategory == category && vm.isAnalyzing
                            )
                        }
                    }

                    if vm.analysisComplete {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title)
                                Text("Regelanalyse faerdig!")
                                    .font(.title2.bold())
                            }

                            Text("\(vm.totalFindings) fund — estimeret tab: \(Int(vm.totalEstimatedLoss).formatted()) kr")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            // LLM progress section
                            if vm.llmEnabled {
                                Divider()
                                    .padding(.vertical, 4)

                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "brain")
                                            .foregroundStyle(.purple)
                                            .font(.title2)

                                        if vm.isLLMAnalyzing {
                                            Text("AI-analyse koerer...")
                                                .font(.title3.bold())
                                            ProgressView()
                                                .controlSize(.small)
                                        } else if vm.llmFindingsCount > 0 {
                                            Text("AI-analyse faerdig")
                                                .font(.title3.bold())
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        } else {
                                            Text("AI-analyse venter...")
                                                .font(.title3.bold())
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if let progress = vm.llmProgress {
                                        Text(progress)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    if vm.llmFindingsCount > 0 {
                                        Text("\(vm.llmFindingsCount) fund verificeret af AI")
                                            .font(.subheadline)
                                            .foregroundStyle(.purple)
                                    }
                                }
                            }

                            Button("Se resultater") {
                                vm.currentTab = .results
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary.opacity(0.5))

                        Text("Importér data og start analysen")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        if vm.canStartAnalysis {
                            Button("Start Analyse") {
                                vm.startAnalysis()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("Importér mindst sygesikringsydelser + dagsprogram eller notater")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.top, 60)
                }

                Spacer()
            }
            .padding(32)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Analyse")
                .font(.largeTitle.bold())
            Text("Krydsrefererer bookinger med ydelser")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct CategoryProgressCard: View {
    let category: AnalysisCategory
    let progress: AppViewModel.CategoryProgress?
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                    .font(.title3)

                VStack(alignment: .leading) {
                    Text(category.rawValue)
                        .font(.caption.bold())
                        .lineLimit(2)
                }

                Spacer()

                if let p = progress, p.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if isCurrent {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let p = progress {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Skannet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(p.recordsProcessed.formatted())")
                            .font(.title3.bold().monospacedDigit())
                            .contentTransition(.numericText())
                            .animation(.snappy, value: p.recordsProcessed)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Fund")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(p.findingsCount)")
                            .font(.title3.bold().monospacedDigit())
                            .foregroundStyle(p.findingsCount > 0 ? category.color : .primary)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: p.findingsCount)
                    }
                }
            } else {
                Text("Venter...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrent ? category.color.opacity(0.05) : Color(.controlBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isCurrent ? category.color.opacity(0.3) : .clear, lineWidth: 1.5)
                }
        }
    }
}
