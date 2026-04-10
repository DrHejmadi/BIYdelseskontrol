import SwiftUI
import Charts

struct ResultsDashboardView: View {
    @Bindable var vm: AppViewModel
    @State private var selectedCategory: AnalysisCategory?

    var body: some View {
        if vm.results.isEmpty {
            ContentUnavailableView(
                "Ingen resultater endnu",
                systemImage: "chart.bar.doc.horizontal",
                description: Text("Kør en analyse for at se resultater")
            )
        } else {
            HSplitView {
                // Left: Overview
                ScrollView {
                    VStack(spacing: 20) {
                        summaryCards
                        chartSection
                        categoryList
                        exportSection
                    }
                    .padding(24)
                }
                .frame(minWidth: 400)

                // Right: Detail
                if let cat = selectedCategory,
                   let result = vm.results.first(where: { $0.category == cat }) {
                    FindingsDetailView(result: result)
                        .frame(minWidth: 400)
                } else {
                    ContentUnavailableView(
                        "Vælg en kategori",
                        systemImage: "hand.point.left",
                        description: Text("Klik på en kategori til venstre for at se detaljer")
                    )
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Samlede fund",
                value: "\(vm.totalFindings)",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
            SummaryCard(
                title: "Estimeret tab",
                value: "\(Int(vm.totalEstimatedLoss).formatted()) kr",
                icon: "banknote",
                color: .red
            )
            SummaryCard(
                title: "Kategorier",
                value: "\(vm.results.count)",
                icon: "square.stack.3d.up",
                color: .blue
            )
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fund per kategori")
                .font(.headline)

            Chart(vm.results, id: \.category) { result in
                BarMark(
                    x: .value("Antal", result.findingsCount),
                    y: .value("Kategori", String(result.category.rawValue.prefix(25)))
                )
                .foregroundStyle(result.category.color)
            }
            .frame(height: CGFloat(vm.results.count) * 40 + 20)
        }
        .padding()
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detaljer per kategori")
                .font(.headline)

            ForEach(vm.results, id: \.category) { result in
                Button {
                    selectedCategory = result.category
                } label: {
                    HStack {
                        Image(systemName: result.category.icon)
                            .foregroundStyle(result.category.color)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text(result.category.rawValue)
                                .font(.subheadline.bold())
                            Text("\(result.findingsCount) fund — \(Int(result.totalEstimatedLoss).formatted()) kr")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedCategory == result.category ? result.category.color.opacity(0.1) : Color.clear)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        VStack(spacing: 12) {
            Button(action: vm.exportResults) {
                Label("Eksportér til Excel", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(vm.isExporting)

            if vm.exportSuccess {
                Label("Eksport gennemført!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
            if let error = vm.exportError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.top)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold().monospacedDigit())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }
}
