import SwiftUI

struct ContentView: View {
    @State private var vm = AppViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $vm.currentTab) {
            Section("Workflow") {
                Label("Import", systemImage: "doc.badge.plus")
                    .tag(AppTab.importData)

                Label("Analyse", systemImage: "chart.bar.doc.horizontal")
                    .tag(AppTab.analysis)
                    .badge(vm.isAnalyzing ? "..." : nil)

                Label("Resultater", systemImage: "checklist")
                    .tag(AppTab.results)
                    .badge(vm.totalFindings > 0 ? "\(vm.totalFindings)" : nil)
            }

            Section {
                Label("AI Motor", systemImage: "brain")
                    .tag(AppTab.llm)

                Label("GDPR", systemImage: "lock.shield")
                    .tag(AppTab.gdpr)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("BI Ydelseskontrol")
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        switch vm.currentTab {
        case .importData:
            ImportView(vm: vm)
        case .analysis:
            AnalysisProgressView(vm: vm)
        case .results:
            ResultsDashboardView(vm: vm)
        case .llm:
            LLMSettingsView(vm: vm)
        case .gdpr:
            GDPRInfoView()
        }
    }
}

#Preview {
    ContentView()
}
