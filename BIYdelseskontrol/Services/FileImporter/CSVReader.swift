import Foundation

enum ImportError: LocalizedError {
    case fileNotFound
    case invalidFormat(String)
    case noData
    case unsupportedFileType

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "Filen blev ikke fundet."
        case .invalidFormat(let detail): return "Ugyldigt filformat: \(detail)"
        case .noData: return "Filen indeholder ingen data."
        case .unsupportedFileType: return "Filtypen understøttes ikke. Brug .csv eller .xlsx"
        }
    }
}

struct CSVReader {
    /// Parse CSV with semicolon or comma delimiter (Danish Excel uses semicolon)
    static func parseRows(from url: URL) throws -> [[String]] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !lines.isEmpty else { throw ImportError.noData }

        // Detect delimiter
        let firstLine = lines[0]
        let delimiter: Character = firstLine.filter({ $0 == ";" }).count > firstLine.filter({ $0 == "," }).count ? ";" : ","

        return lines.map { line in
            line.split(separator: delimiter, omittingEmptySubsequences: false).map {
                $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
    }

    static func parseBillingRecords(from url: URL) throws -> [BillingRecord] {
        let rows = try parseRows(from: url)
        guard rows.count > 1 else { throw ImportError.noData }

        let header = rows[0].map { $0.lowercased() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "da_DK")

        return rows.dropFirst().compactMap { row in
            guard row.count >= 6 else { return nil }

            let cprIdx = header.firstIndex(where: { $0.contains("cpr") }) ?? 0
            let datoIdx = header.firstIndex(where: { $0.contains("dato") }) ?? 4
            let kodeIdx = header.firstIndex(where: { $0.contains("kode") }) ?? 5
            let beloebIdx = header.firstIndex(where: { $0.contains("beløb") || $0.contains("belob") }) ?? 6
            let initialerIdx = header.firstIndex(where: { $0.contains("initial") }) ?? (row.count - 1)

            let cprRaw = row[safe: cprIdx] ?? ""
            let cpr = normalizeCPR(cprRaw)
            let datoStr = row[safe: datoIdx] ?? ""
            let dato = dateFormatter.date(from: datoStr) ?? Date()
            let kode = Int(row[safe: kodeIdx] ?? "") ?? 0
            let beloeb = Double((row[safe: beloebIdx] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0

            return BillingRecord(
                cprnr: cpr,
                fornavn: row[safe: 1] ?? "",
                efternavn: row[safe: 2] ?? "",
                behandler: row[safe: 3] ?? "",
                ydelsesdato: dato,
                ydelsesdatoStr: datoStr,
                ydelseskode: kode,
                ydelsestekst: row[safe: (kodeIdx + 1)] ?? "",
                antal: Int(row[safe: (kodeIdx + 2)] ?? "") ?? 1,
                ydelsesbeloeb: beloeb,
                initialerPaaYdelse: (row[safe: initialerIdx] ?? "").trimmingCharacters(in: .whitespaces)
            )
        }
    }

    static func parseBookingRecords(from url: URL) throws -> [BookingRecord] {
        let rows = try parseRows(from: url)
        guard rows.count > 1 else { throw ImportError.noData }

        let header = rows[0].map { $0.lowercased() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "da_DK")

        let datoIdx = header.firstIndex(where: { $0.contains("dato") }) ?? 0
        let tidStartIdx = header.firstIndex(where: { $0.contains("start") || $0.contains("tid") }) ?? 1
        let tidSlutIdx = header.firstIndex(where: { $0.contains("slut") }) ?? 2
        let cprIdx = header.firstIndex(where: { $0.contains("cpr") }) ?? 3
        let navnIdx = header.firstIndex(where: { $0.contains("navn") }) ?? 4
        let emneIdx = header.firstIndex(where: { $0.contains("emne") || $0.contains("årsag") || $0.contains("aarsag") || $0.contains("reason") }) ?? 5
        let laegeIdx = header.firstIndex(where: { $0.contains("læge") || $0.contains("laege") || $0.contains("initial") || $0.contains("doctor") }) ?? 6

        return rows.dropFirst().compactMap { row in
            guard row.count >= 4 else { return nil }

            let datoStr = row[safe: datoIdx] ?? ""
            let dato = dateFormatter.date(from: datoStr) ?? Date()
            let cpr = normalizeCPR(row[safe: cprIdx] ?? "")

            return BookingRecord(
                dato: dato,
                datoStr: datoStr,
                tidStart: row[safe: tidStartIdx] ?? "",
                tidSlut: row[safe: tidSlutIdx],
                cpr: cpr,
                navn: row[safe: navnIdx] ?? "",
                emneAarsag: row[safe: emneIdx] ?? "",
                laege: row[safe: laegeIdx] ?? ""
            )
        }
    }

    static func parseNoteRecords(from url: URL) throws -> [NoteRecord] {
        let rows = try parseRows(from: url)
        guard rows.count > 1 else { throw ImportError.noData }

        let header = rows[0].map { $0.lowercased() }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "da_DK")

        let cprIdx = header.firstIndex(where: { $0.contains("cpr") }) ?? 0
        let fornavnIdx = header.firstIndex(where: { $0.contains("fornavn") }) ?? 1
        let efternavnIdx = header.firstIndex(where: { $0.contains("efternavn") }) ?? 2
        let datoIdx = header.firstIndex(where: { $0.contains("dato") }) ?? 3
        let emneIdx = header.firstIndex(where: { $0.contains("emne") }) ?? 4
        let notatIdx = header.firstIndex(where: { $0.contains("notat") }) ?? 5

        return rows.dropFirst().compactMap { row in
            guard row.count >= 4 else { return nil }

            let datoStr = row[safe: datoIdx] ?? ""
            let dato = dateFormatter.date(from: datoStr) ?? Date()

            return NoteRecord(
                cpr: normalizeCPR(row[safe: cprIdx] ?? ""),
                fornavn: row[safe: fornavnIdx] ?? "",
                efternavn: row[safe: efternavnIdx] ?? "",
                dato: dato,
                datoStr: datoStr,
                emne: row[safe: emneIdx] ?? "",
                notat: row[safe: notatIdx] ?? ""
            )
        }
    }
}

/// Normalize CPR to 10-digit string (handles both "XXXXXX-XXXX" and int formats)
func normalizeCPR(_ raw: String) -> String {
    let cleaned = raw.replacingOccurrences(of: "-", with: "")
                     .replacingOccurrences(of: " ", with: "")
                     .trimmingCharacters(in: .whitespaces)
    // Zero-pad to 10 digits (handles cases where leading zero was dropped)
    if cleaned.count < 10 && !cleaned.isEmpty {
        return String(repeating: "0", count: 10 - cleaned.count) + cleaned
    }
    return String(cleaned.prefix(10))
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
