import Foundation

struct BookingRecord: Identifiable, Sendable {
    let id = UUID()
    let dato: Date
    let datoStr: String         // Original date string
    let tidStart: String        // "HH:MM"
    let tidSlut: String?        // "HH:MM" or nil
    let cpr: String             // 10-digit, normalized
    let navn: String
    let emneAarsag: String      // Booking reason/topic
    let laege: String           // Doctor initials

    /// Duration in minutes (0 if unknown)
    var varighedMinutter: Int {
        guard let slut = tidSlut else { return 0 }
        let parts1 = tidStart.split(separator: ":")
        let parts2 = slut.split(separator: ":")
        guard parts1.count == 2, parts2.count == 2,
              let h1 = Int(parts1[0]), let m1 = Int(parts1[1]),
              let h2 = Int(parts2[0]), let m2 = Int(parts2[1]) else { return 0 }
        return (h2 * 60 + m2) - (h1 * 60 + m1)
    }
}

/// Classification of a booking type
enum BookingType: String, Sendable {
    case video = "Video"
    case besoeg = "Besøg"
    case samtale = "Samtale"
    case opkaldSvar = "Opkald/Svar"
    case eKonsOnline = "E-kons/Online"
    case fremmoede = "Fremmøde"
    case ukendt = "Ukendt"
}

extension BookingRecord {
    /// Classify booking type based on reason text
    var bookingType: BookingType {
        let lower = emneAarsag.lowercased()

        if lower.contains("video") {
            return .video
        }
        if lower.contains("besøg") || lower.contains("besog") || lower.contains("hjemmebesøg") {
            return .besoeg
        }
        if lower.contains("samtale") || lower.contains("krise") || lower.contains("psyk") ||
           lower.contains("terapi") || lower.contains("angst") || lower.contains("depression") {
            return .samtale
        }
        if lower.contains("ring") || lower.contains("svar") || lower.contains("opkald") ||
           lower.contains("tk svar") || lower.contains("sygepl") {
            return .opkaldSvar
        }
        if lower.contains("online") || lower.contains("minlæge") || lower.contains("e-kons") ||
           lower.contains("ekons") || lower.contains("mail") {
            return .eKonsOnline
        }
        if varighedMinutter >= 10 {
            return .fremmoede
        }
        return .ukendt
    }
}
