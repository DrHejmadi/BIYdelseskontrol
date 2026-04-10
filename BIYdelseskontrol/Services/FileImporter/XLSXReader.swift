import Foundation
import CoreXLSX

struct XLSXReader {
    static func parseBillingRecords(from url: URL) throws -> [BillingRecord] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.invalidFormat("Kunne ikke åbne XLSX-fil")
        }
        let sharedStrings = try file.parseSharedStrings()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "da_DK")

        var records: [BillingRecord] = []

        for wbk in try file.parseWorkbooks() {
            for (_, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                let worksheet = try file.parseWorksheet(at: path)
                guard let rows = worksheet.data?.rows, rows.count > 1 else { continue }

                // First row = header — detect column indices
                let headerRow = rows[0]
                let headerCells = headerRow.cells.map { cellValue($0, sharedStrings: sharedStrings).lowercased() }

                let cprIdx = headerCells.firstIndex(where: { $0.contains("cpr") }) ?? 0
                let fornavnIdx = headerCells.firstIndex(where: { $0.contains("fornavn") }) ?? 1
                let efternavnIdx = headerCells.firstIndex(where: { $0.contains("efternavn") }) ?? 2
                let behandlerIdx = headerCells.firstIndex(where: { $0.contains("behandler") }) ?? 3
                let datoIdx = headerCells.firstIndex(where: { $0.contains("ydelsesdato") || $0.contains("dato") }) ?? 4
                let kodeIdx = headerCells.firstIndex(where: { $0.contains("ydelseskode") || $0.contains("kode") }) ?? 5
                let tekstIdx = headerCells.firstIndex(where: { $0.contains("ydelsestekst") || $0.contains("tekst") }) ?? 6
                let antalIdx = headerCells.firstIndex(where: { $0.contains("antal") }) ?? 7
                let beloebIdx = headerCells.firstIndex(where: { $0.contains("beløb") || $0.contains("belob") || $0.contains("ydelsesbeløb") }) ?? 8
                let initialerIdx = headerCells.firstIndex(where: { $0.contains("initial") }) ?? (headerCells.count - 1)

                for row in rows.dropFirst() {
                    let cells = row.cells
                    func val(_ idx: Int) -> String {
                        guard idx < cells.count else { return "" }
                        return cellValue(cells[idx], sharedStrings: sharedStrings)
                    }

                    let cprRaw = val(cprIdx)
                    let cpr = normalizeCPR(cprRaw)
                    guard !cpr.isEmpty && cpr != "0000000000" else { continue }

                    let datoStr = val(datoIdx)
                    let dato = dateFormatter.date(from: datoStr) ?? parseExcelDate(val(datoIdx))
                    let kode = Int(val(kodeIdx).trimmingCharacters(in: .whitespaces)) ?? Int(Double(val(kodeIdx)) ?? 0)
                    let beloeb = Double(val(beloebIdx).replacingOccurrences(of: ",", with: ".")) ?? 0

                    records.append(BillingRecord(
                        cprnr: cpr,
                        fornavn: val(fornavnIdx),
                        efternavn: val(efternavnIdx),
                        behandler: val(behandlerIdx),
                        ydelsesdato: dato,
                        ydelsesdatoStr: datoStr.isEmpty ? formatDate(dato) : datoStr,
                        ydelseskode: kode,
                        ydelsestekst: val(tekstIdx),
                        antal: Int(val(antalIdx)) ?? 1,
                        ydelsesbeloeb: beloeb,
                        initialerPaaYdelse: val(initialerIdx).trimmingCharacters(in: .whitespaces)
                    ))
                }
            }
        }
        return records
    }

    static func parseBookingRecords(from url: URL) throws -> [BookingRecord] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.invalidFormat("Kunne ikke åbne XLSX-fil")
        }
        let sharedStrings = try file.parseSharedStrings()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "da_DK")

        var records: [BookingRecord] = []

        for wbk in try file.parseWorkbooks() {
            for (_, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                let worksheet = try file.parseWorksheet(at: path)
                guard let rows = worksheet.data?.rows, rows.count > 1 else { continue }

                let headerCells = rows[0].cells.map { cellValue($0, sharedStrings: sharedStrings).lowercased() }
                let datoIdx = headerCells.firstIndex(where: { $0.contains("dato") }) ?? 0
                let tidStartIdx = headerCells.firstIndex(where: { $0.contains("start") || $0 == "tid" }) ?? 1
                let tidSlutIdx = headerCells.firstIndex(where: { $0.contains("slut") }) ?? 2
                let cprIdx = headerCells.firstIndex(where: { $0.contains("cpr") }) ?? 3
                let navnIdx = headerCells.firstIndex(where: { $0.contains("navn") }) ?? 4
                let emneIdx = headerCells.firstIndex(where: { $0.contains("emne") || $0.contains("årsag") }) ?? 5
                let laegeIdx = headerCells.firstIndex(where: { $0.contains("læge") || $0.contains("initial") }) ?? 6

                for row in rows.dropFirst() {
                    let cells = row.cells
                    func val(_ idx: Int) -> String {
                        guard idx < cells.count else { return "" }
                        return cellValue(cells[idx], sharedStrings: sharedStrings)
                    }

                    let cpr = normalizeCPR(val(cprIdx))
                    guard !cpr.isEmpty else { continue }

                    let datoStr = val(datoIdx)
                    let dato = dateFormatter.date(from: datoStr) ?? parseExcelDate(datoStr)

                    records.append(BookingRecord(
                        dato: dato,
                        datoStr: datoStr.isEmpty ? formatDate(dato) : datoStr,
                        tidStart: val(tidStartIdx),
                        tidSlut: val(tidSlutIdx).isEmpty ? nil : val(tidSlutIdx),
                        cpr: cpr,
                        navn: val(navnIdx),
                        emneAarsag: val(emneIdx),
                        laege: val(laegeIdx)
                    ))
                }
            }
        }
        return records
    }

    static func parseNoteRecords(from url: URL) throws -> [NoteRecord] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.invalidFormat("Kunne ikke åbne XLSX-fil")
        }
        let sharedStrings = try file.parseSharedStrings()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "da_DK")

        var records: [NoteRecord] = []

        for wbk in try file.parseWorkbooks() {
            for (_, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                let worksheet = try file.parseWorksheet(at: path)
                guard let rows = worksheet.data?.rows, rows.count > 1 else { continue }

                let headerCells = rows[0].cells.map { cellValue($0, sharedStrings: sharedStrings).lowercased() }
                let cprIdx = headerCells.firstIndex(where: { $0.contains("cpr") }) ?? 0
                let fornavnIdx = headerCells.firstIndex(where: { $0.contains("fornavn") }) ?? 1
                let efternavnIdx = headerCells.firstIndex(where: { $0.contains("efternavn") }) ?? 2
                let datoIdx = headerCells.firstIndex(where: { $0.contains("dato") }) ?? 3
                let emneIdx = headerCells.firstIndex(where: { $0.contains("emne") }) ?? 4
                let notatIdx = headerCells.firstIndex(where: { $0.contains("notat") }) ?? 5

                for row in rows.dropFirst() {
                    let cells = row.cells
                    func val(_ idx: Int) -> String {
                        guard idx < cells.count else { return "" }
                        return cellValue(cells[idx], sharedStrings: sharedStrings)
                    }

                    let datoStr = val(datoIdx)
                    let dato = dateFormatter.date(from: datoStr) ?? parseExcelDate(datoStr)

                    records.append(NoteRecord(
                        cpr: normalizeCPR(val(cprIdx)),
                        fornavn: val(fornavnIdx),
                        efternavn: val(efternavnIdx),
                        dato: dato,
                        datoStr: datoStr.isEmpty ? formatDate(dato) : datoStr,
                        emne: val(emneIdx),
                        notat: val(notatIdx)
                    ))
                }
            }
        }
        return records
    }

    // MARK: - Helpers

    private static func cellValue(_ cell: Cell, sharedStrings: SharedStrings?) -> String {
        if let sharedStrings = sharedStrings, cell.type == .sharedString,
           let idx = cell.value.flatMap(Int.init) {
            return sharedStrings.items[safe: idx]?.text ?? ""
        }
        return cell.value ?? ""
    }
}

/// Parse Excel serial date number to Date
func parseExcelDate(_ value: String) -> Date {
    if let serial = Double(value) {
        // Excel serial: days since 1899-12-30
        let referenceDate = DateComponents(calendar: Calendar(identifier: .gregorian),
                                           year: 1899, month: 12, day: 30).date!
        return Calendar.current.date(byAdding: .day, value: Int(serial), to: referenceDate) ?? Date()
    }
    // Try alternate formats
    let formats = ["dd/MM/yyyy", "yyyy-MM-dd", "dd.MM.yyyy", "MM/dd/yyyy"]
    for fmt in formats {
        let df = DateFormatter()
        df.dateFormat = fmt
        if let d = df.date(from: value) { return d }
    }
    return Date()
}

func formatDate(_ date: Date) -> String {
    let df = DateFormatter()
    df.dateFormat = "dd-MM-yyyy"
    return df.string(from: date)
}
