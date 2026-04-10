import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Bindable var vm: AppViewModel
    @State private var showBillingPicker = false
    @State private var showBookingPicker = false
    @State private var showNotesPicker = false

    private let allowedTypes: [UTType] = [
        .commaSeparatedText,
        UTType(filenameExtension: "xlsx") ?? .data,
        UTType(filenameExtension: "xls") ?? .data,
        .data
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                // File drop zones
                VStack(spacing: 16) {
                    FileDropZone(
                        title: "Sygesikringsydelser",
                        subtitle: "Excel eller CSV med alle ydelser",
                        icon: "creditcard",
                        fileURL: vm.billingFileURL,
                        recordCount: vm.billingRecords.count,
                        isRequired: true,
                        onTap: { showBillingPicker = true }
                    )

                    FileDropZone(
                        title: "Dagsprogram",
                        subtitle: "Excel eller CSV med bookinger",
                        icon: "calendar",
                        fileURL: vm.bookingFileURL,
                        recordCount: vm.bookingRecords.count,
                        isRequired: true,
                        onTap: { showBookingPicker = true }
                    )

                    FileDropZone(
                        title: "Notater uden ydelse",
                        subtitle: "Excel eller CSV med journalnotater (valgfri)",
                        icon: "doc.text",
                        fileURL: vm.notesFileURL,
                        recordCount: vm.noteRecords.count,
                        isRequired: false,
                        onTap: { showNotesPicker = true }
                    )
                }

                if let error = vm.importError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                // Start button
                Button(action: {
                    vm.currentTab = .analysis
                    vm.startAnalysis()
                }) {
                    Label("Start Analyse", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(!vm.canStartAnalysis)
                .padding(.top, 8)

                Spacer()
            }
            .padding(32)
        }
        .fileImporter(isPresented: $showBillingPicker, allowedContentTypes: allowedTypes) { result in
            if case .success(let url) = result { vm.importFile(url, type: .billing) }
        }
        .fileImporter(isPresented: $showBookingPicker, allowedContentTypes: allowedTypes) { result in
            if case .success(let url) = result { vm.importFile(url, type: .booking) }
        }
        .fileImporter(isPresented: $showNotesPicker, allowedContentTypes: allowedTypes) { result in
            if case .success(let url) = result { vm.importFile(url, type: .notes) }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "stethoscope")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("BI Ydelseskontrol")
                .font(.largeTitle.bold())

            Text("Importér dine data for at finde manglende og forkerte ydelser")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
}
