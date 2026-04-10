import Foundation

/// Orchestrates file import — detects format and delegates to CSV or XLSX reader
struct DataImportService {
    enum FileType {
        case csv, xlsx

        static func detect(url: URL) -> FileType {
            let ext = url.pathExtension.lowercased()
            if ext == "csv" || ext == "tsv" || ext == "txt" {
                return .csv
            }
            // Default to xlsx for everything else (including files without extension)
            return .xlsx
        }
    }

    static func importBillingRecords(from url: URL) throws -> [BillingRecord] {
        switch FileType.detect(url: url) {
        case .csv:
            return try CSVReader.parseBillingRecords(from: url)
        case .xlsx:
            return try XLSXReader.parseBillingRecords(from: url)
        }
    }

    static func importBookingRecords(from url: URL) throws -> [BookingRecord] {
        switch FileType.detect(url: url) {
        case .csv:
            return try CSVReader.parseBookingRecords(from: url)
        case .xlsx:
            return try XLSXReader.parseBookingRecords(from: url)
        }
    }

    static func importNoteRecords(from url: URL) throws -> [NoteRecord] {
        switch FileType.detect(url: url) {
        case .csv:
            return try CSVReader.parseNoteRecords(from: url)
        case .xlsx:
            return try XLSXReader.parseNoteRecords(from: url)
        }
    }
}
