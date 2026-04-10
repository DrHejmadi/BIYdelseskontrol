import Foundation

struct BillingRecord: Identifiable, Sendable {
    let id = UUID()
    let cprnr: String           // 10-digit, zero-padded
    let fornavn: String
    let efternavn: String
    let behandler: String
    let ydelsesdato: Date
    let ydelsesdatoStr: String  // Original "DD-MM-YYYY"
    let ydelseskode: Int
    let ydelsestekst: String
    let antal: Int
    let ydelsesbeloeb: Double
    let initialerPaaYdelse: String
}
