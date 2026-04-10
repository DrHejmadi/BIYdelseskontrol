import SwiftUI

struct LLMSettingsView: View {
    @Bindable var vm: AppViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statusSection
                settingsSection
                installGuideSection
                if vm.llmFindingsCount > 0 {
                    llmResultsSection
                }
                Spacer()
            }
            .padding(32)
        }
        .task {
            await vm.checkOllama()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("AI Motor")
                .font(.largeTitle.bold())
            Text("Lokal LLM-analyse med Ollama")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(vm.ollamaRunning ? .green : .red)
                .frame(width: 12, height: 12)

            Text(vm.ollamaRunning ? "Ollama koerer" : "Ollama koerer ikke")
                .font(.headline)

            Spacer()

            Button("Tjek forbindelse") {
                Task { await vm.checkOllama() }
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Brug lokal AI-analyse (Ollama)", isOn: $vm.llmEnabled)
                .toggleStyle(.switch)

            if vm.llmEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.subheadline.bold())

                    if vm.ollamaModels.isEmpty {
                        Text("Ingen modeller fundet. Start Ollama og tryk 'Tjek forbindelse'.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Model", selection: $vm.llmModelName) {
                            ForEach(vm.ollamaModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .labelsHidden()
                    }
                }

                Text("AI-analysen koerer lokalt paa din computer. Ingen data forlader maskinen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }

    // MARK: - Install Guide

    private var installGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text("Installation")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("1. Installer Ollama:")
                    .font(.subheadline.bold())
                Text("brew install ollama")
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)

                Text("2. Start Ollama:")
                    .font(.subheadline.bold())
                Text("ollama serve")
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)

                Text("3. Hent en model:")
                    .font(.subheadline.bold())
                Text("ollama pull llama3.1:8b")
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - LLM Results

    private var llmResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .foregroundStyle(.purple)
                Text("Seneste AI-analyse")
                    .font(.headline)
            }

            Text("\(vm.llmFindingsCount) fund behandlet af AI")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let progress = vm.llmProgress {
                Text(progress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        }
    }
}
