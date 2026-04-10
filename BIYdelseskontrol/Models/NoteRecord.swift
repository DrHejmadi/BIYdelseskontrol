import Foundation

struct NoteRecord: Identifiable, Sendable {
    let id = UUID()
    let cpr: String             // Normalized 10-digit or "XXXXXX-XXXX"
    let fornavn: String
    let efternavn: String
    let dato: Date
    let datoStr: String
    let emne: String            // "ALM", "EML", "FYS", etc.
    let notat: String           // Full note text

    /// Whether this note is patient-initiated (no billing allowed per overenskomst)
    var erPatientInitieret: Bool {
        notat.contains("* Mail fra patient *") ||
        notat.contains("*Mail fra patient*") ||
        emne == "EML"
    }
}
