import SwiftUI

struct FileDropZone: View {
    let title: String
    let subtitle: String
    let icon: String
    let fileURL: URL?
    let recordCount: Int
    let isRequired: Bool
    let onTap: () -> Void

    @State private var isTargeted = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(fileURL != nil ? .green : .blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if isRequired {
                            Text("Påkrævet")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.2), in: Capsule())
                                .foregroundStyle(.orange)
                        }
                    }

                    if let url = fileURL {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(recordCount.formatted()) poster indlæst")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if fileURL != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? Color.blue.opacity(0.1) : (fileURL != nil ? Color.green.opacity(0.05) : Color(.controlBackgroundColor)))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isTargeted ? Color.blue : (fileURL != nil ? Color.green.opacity(0.3) : Color.gray.opacity(0.2)),
                                style: fileURL == nil ? StrokeStyle(lineWidth: 1.5, dash: [6]) : StrokeStyle(lineWidth: 1)
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async { onTap() }
                }
            }
            return true
        }
    }
}
