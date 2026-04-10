import Foundation

/// Lightweight XLSX writer — generates valid .xlsx files (ZIP of XML)
/// No external dependencies needed
struct XLSXExporter {

    /// Export all analysis results to a single .xlsx file with one sheet per category + overview
    static func export(results: [AnalysisResult], to url: URL) throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Build sheets
        var sheets: [(name: String, data: [[String]])] = []

        // Overview sheet
        var overview: [[String]] = [
            ["Kategori", "Antal fund", "Estimeret tab (kr)", "Overenskomsttekst"]
        ]
        var totalFindings = 0
        var totalLoss = 0.0
        for result in results {
            totalFindings += result.findingsCount
            totalLoss += result.totalEstimatedLoss
            overview.append([
                result.category.rawValue,
                "\(result.findingsCount)",
                String(format: "%.0f", result.totalEstimatedLoss),
                result.category.overenskomstTekst
            ])
        }
        overview.append([])
        overview.append(["TOTAL", "\(totalFindings)", String(format: "%.0f", totalLoss), ""])
        sheets.append(("Oversigt", overview))

        // Detail sheets
        for result in results {
            let sheetName = String(result.category.rawValue.prefix(31)) // Excel max 31 chars
            var rows: [[String]] = [
                ["CPR", "Navn", "Dato", "Booking/Emne", "Forventet ydelse", "Faktisk ydelse",
                 "Læge", "Problem", "Estimeret tab", "Kontrolleret", "Kommentar"]
            ]
            for f in result.findings {
                rows.append([
                    f.cpr, f.navn, f.datoStr, f.bookingEmne,
                    f.expectedYdelse, f.actualYdelse, f.laege,
                    f.problem, String(format: "%.0f", f.estimatedLoss), "", ""
                ])
            }
            sheets.append((sheetName, rows))
        }

        // Generate XLSX (ZIP of XML files)
        try writeXLSX(sheets: sheets, to: url, tempDir: tempDir)
    }

    // MARK: - XLSX File Generation

    private static func writeXLSX(sheets: [(name: String, data: [[String]])], to url: URL, tempDir: URL) throws {
        // Create directory structure
        let xlDir = tempDir.appendingPathComponent("xl")
        let wsDir = xlDir.appendingPathComponent("worksheets")
        let relsDir = tempDir.appendingPathComponent("_rels")
        let xlRelsDir = xlDir.appendingPathComponent("_rels")
        for dir in [xlDir, wsDir, relsDir, xlRelsDir] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Collect all unique strings for shared strings table
        var allStrings: [String] = []
        var stringIndex: [String: Int] = [:]
        for (_, data) in sheets {
            for row in data {
                for cell in row {
                    if stringIndex[cell] == nil {
                        stringIndex[cell] = allStrings.count
                        allStrings.append(cell)
                    }
                }
            }
        }

        // [Content_Types].xml
        var contentTypes = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
        <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>

        """
        for i in 0..<sheets.count {
            contentTypes += "<Override PartName=\"/xl/worksheets/sheet\(i+1).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>\n"
        }
        contentTypes += "</Types>"
        try contentTypes.write(to: tempDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)

        // _rels/.rels
        let rootRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
        try rootRels.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)

        // xl/_rels/workbook.xml.rels
        var wbRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rIdSS" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
        <Relationship Id="rIdSt" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>

        """
        for i in 0..<sheets.count {
            wbRels += "<Relationship Id=\"rId\(i+1)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet\(i+1).xml\"/>\n"
        }
        wbRels += "</Relationships>"
        try wbRels.write(to: xlRelsDir.appendingPathComponent("workbook.xml.rels"), atomically: true, encoding: .utf8)

        // xl/workbook.xml
        var workbook = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>

        """
        for (i, sheet) in sheets.enumerated() {
            let safeName = xmlEscape(sheet.name)
            workbook += "<sheet name=\"\(safeName)\" sheetId=\"\(i+1)\" r:id=\"rId\(i+1)\"/>\n"
        }
        workbook += "</sheets></workbook>"
        try workbook.write(to: xlDir.appendingPathComponent("workbook.xml"), atomically: true, encoding: .utf8)

        // xl/styles.xml — minimal with bold header and red fill
        let styles = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <fonts count="2">
        <font><sz val="11"/><name val="Calibri"/></font>
        <font><b/><sz val="11"/><name val="Calibri"/></font>
        </fonts>
        <fills count="3">
        <fill><patternFill patternType="none"/></fill>
        <fill><patternFill patternType="gray125"/></fill>
        <fill><patternFill patternType="solid"><fgColor rgb="FFE8F5E9"/></patternFill></fill>
        </fills>
        <borders count="1"><border/></borders>
        <cellStyleXfs count="1"><xf/></cellStyleXfs>
        <cellXfs count="3">
        <xf/>
        <xf fontId="1" fillId="2" applyFont="1" applyFill="1"/>
        <xf fontId="0"/>
        </cellXfs>
        </styleSheet>
        """
        try styles.write(to: xlDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)

        // xl/sharedStrings.xml
        var ss = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="\(allStrings.count)" uniqueCount="\(allStrings.count)">

        """
        for s in allStrings {
            ss += "<si><t>\(xmlEscape(s))</t></si>\n"
        }
        ss += "</sst>"
        try ss.write(to: xlDir.appendingPathComponent("sharedStrings.xml"), atomically: true, encoding: .utf8)

        // Worksheets
        for (i, sheet) in sheets.enumerated() {
            var ws = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
            <sheetData>

            """
            for (rowIdx, row) in sheet.data.enumerated() {
                ws += "<row r=\"\(rowIdx + 1)\">"
                for (colIdx, cell) in row.enumerated() {
                    let colLetter = columnLetter(colIdx)
                    let cellRef = "\(colLetter)\(rowIdx + 1)"
                    let styleIdx = rowIdx == 0 ? 1 : 0 // Bold header
                    if let idx = stringIndex[cell] {
                        ws += "<c r=\"\(cellRef)\" t=\"s\" s=\"\(styleIdx)\"><v>\(idx)</v></c>"
                    }
                }
                ws += "</row>\n"
            }
            ws += "</sheetData></worksheet>"
            try ws.write(to: wsDir.appendingPathComponent("sheet\(i+1).xml"), atomically: true, encoding: .utf8)
        }

        // ZIP everything into .xlsx
        try zipDirectory(tempDir, to: url)
    }

    private static func columnLetter(_ index: Int) -> String {
        var result = ""
        var idx = index
        repeat {
            result = String(Character(UnicodeScalar(65 + idx % 26)!)) + result
            idx = idx / 26 - 1
        } while idx >= 0
        return result
    }

    private static func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    /// ZIP a directory into a file using ditto (macOS built-in)
    private static func zipDirectory(_ dir: URL, to output: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", dir.path, output.path]

        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            // Fallback: use zip command
            let zipProcess = Process()
            zipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            zipProcess.currentDirectoryURL = dir
            zipProcess.arguments = ["-r", output.path, "."]
            try zipProcess.run()
            zipProcess.waitUntilExit()
        }
    }
}
