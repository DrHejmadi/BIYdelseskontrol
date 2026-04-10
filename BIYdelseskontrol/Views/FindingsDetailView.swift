import SwiftUI

struct FindingsDetailView: View {
    let result: AnalysisResult

    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\AnalysisFinding.datoStr)]

    var filteredFindings: [AnalysisFinding] {
        if searchText.isEmpty {
            return result.findings
        }
        let query = searchText.lowercased()
        return result.findings.filter {
            $0.navn.lowercased().contains(query) ||
            $0.cpr.contains(query) ||
            $0.bookingEmne.lowercased().contains(query) ||
            $0.laege.lowercased().contains(query) ||
            $0.problem.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: result.category.icon)
                        .foregroundStyle(result.category.color)
                    Text(result.category.rawValue)
                        .font(.headline)
                }

                Text(result.category.overenskomstTekst)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

                HStack {
                    Label("\(result.findingsCount) fund", systemImage: "exclamationmark.triangle")
                    Spacer()
                    Label("\(Int(result.totalEstimatedLoss).formatted()) kr estimeret tab", systemImage: "banknote")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Søg i fund...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(.controlBackgroundColor))

            Divider()

            // Table
            Table(filteredFindings, sortOrder: $sortOrder) {
                TableColumn("Dato", value: \.datoStr) { finding in
                    Text(finding.datoStr)
                        .font(.caption.monospacedDigit())
                }
                .width(min: 80, ideal: 90)

                TableColumn("CPR", value: \.cpr) { finding in
                    Text(finding.cpr)
                        .font(.caption.monospacedDigit())
                }
                .width(min: 85, ideal: 95)

                TableColumn("Navn", value: \.navn) { finding in
                    Text(finding.navn)
                        .font(.caption)
                }
                .width(min: 100, ideal: 130)

                TableColumn("Booking/Emne", value: \.bookingEmne) { finding in
                    Text(finding.bookingEmne)
                        .font(.caption)
                        .lineLimit(2)
                }
                .width(min: 120, ideal: 180)

                TableColumn("Problem", value: \.problem) { finding in
                    Text(finding.problem)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .width(min: 100, ideal: 160)

                TableColumn("Læge", value: \.laege) { finding in
                    Text(finding.laege)
                        .font(.caption)
                }
                .width(min: 40, ideal: 50)

                TableColumn("Tab (kr)") { finding in
                    Text(String(format: "%.0f", finding.estimatedLoss))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.red)
                }
                .width(min: 50, ideal: 60)

                TableColumn("AI") { finding in
                    if let confirmed = finding.llmConfirmed {
                        Image(systemName: confirmed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(confirmed ? .green : .orange)
                            .help(finding.llmExplanation ?? "")
                    }
                }
                .width(min: 30, ideal: 35)

                TableColumn("AI Forklaring") { finding in
                    if let explanation = finding.llmExplanation {
                        Text(explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .width(min: 100, ideal: 180)
            }
        }
    }
}
