import AppKit
import Foundation

// MARK: - Constants
let width = 2880
let height = 1800
let screenshotSize = NSSize(width: width, height: height)

// MARK: - Colors
let medicalBlue = NSColor(calibratedRed: 30/255, green: 136/255, blue: 229/255, alpha: 1.0)    // #1E88E5
let darkBlue = NSColor(calibratedRed: 13/255, green: 71/255, blue: 161/255, alpha: 1.0)        // #0D47A1
let white = NSColor.white
let lightGray = NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.97, alpha: 1.0)
let cardShadowGray = NSColor(calibratedRed: 0.85, green: 0.87, blue: 0.90, alpha: 1.0)
let textDark = NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.20, alpha: 1.0)
let textMedium = NSColor(calibratedRed: 0.40, green: 0.42, blue: 0.48, alpha: 1.0)
let textLight = NSColor(calibratedRed: 0.60, green: 0.62, blue: 0.66, alpha: 1.0)
let accentGreen = NSColor(calibratedRed: 0.18, green: 0.72, blue: 0.53, alpha: 1.0)
let accentOrange = NSColor(calibratedRed: 0.95, green: 0.60, blue: 0.20, alpha: 1.0)
let accentRed = NSColor(calibratedRed: 0.90, green: 0.30, blue: 0.25, alpha: 1.0)
let sidebarBg = NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.20, alpha: 1.0)
let sidebarText = NSColor(calibratedRed: 0.70, green: 0.73, blue: 0.80, alpha: 1.0)
let sidebarActive = NSColor(calibratedRed: 30/255, green: 136/255, blue: 229/255, alpha: 0.20)

let outputDir = URL(fileURLWithPath: #file).deletingLastPathComponent()

// MARK: - Helper Functions

func createBitmapContext() -> NSBitmapImageRep {
    return NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
}

func saveImage(_ rep: NSBitmapImageRep, name: String) {
    let url = outputDir.appendingPathComponent(name)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: url)
    print("Saved: \(url.path)")
}

func drawGradientHeader(_ context: NSGraphicsContext, rect: NSRect) {
    let gc = context.cgContext
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [darkBlue.cgColor, medicalBlue.cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    gc.saveGState()
    gc.clip(to: rect)
    gc.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
    gc.restoreGState()
}

func drawRoundedRect(_ context: NSGraphicsContext, rect: NSRect, radius: CGFloat, fillColor: NSColor, shadowOffset: CGFloat = 0) {
    let gc = context.cgContext
    if shadowOffset > 0 {
        gc.saveGState()
        gc.setShadow(offset: CGSize(width: 0, height: -shadowOffset), blur: shadowOffset * 2, color: NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.08).cgColor)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        fillColor.setFill()
        path.fill()
        gc.restoreGState()
    } else {
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        fillColor.setFill()
        path.fill()
    }
}

func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor, maxWidth: CGFloat = 0) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    if maxWidth > 0 {
        let rect = NSRect(x: point.x, y: point.y, width: maxWidth, height: 200)
        text.draw(in: rect, withAttributes: attrs)
    } else {
        text.draw(at: point, withAttributes: attrs)
    }
}

func drawCenteredText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let size = text.size(withAttributes: attrs)
    let x = rect.origin.x + (rect.width - size.width) / 2
    let y = rect.origin.y + (rect.height - size.height) / 2
    text.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
}

func drawSidebar(_ context: NSGraphicsContext, activeIndex: Int) {
    let sidebarWidth: CGFloat = 340
    let sidebarRect = NSRect(x: 0, y: 0, width: sidebarWidth, height: CGFloat(height))

    // Sidebar background
    sidebarBg.setFill()
    sidebarRect.fill()

    // App icon area
    let iconY = CGFloat(height) - 140
    drawText("BI", at: NSPoint(x: 40, y: iconY), font: NSFont.boldSystemFont(ofSize: 42), color: medicalBlue)
    drawText("Ydelseskontrol", at: NSPoint(x: 110, y: iconY + 4), font: NSFont.systemFont(ofSize: 30, weight: .light), color: white)

    // Divider
    let dividerY = iconY - 30
    NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.08).setFill()
    NSRect(x: 24, y: dividerY, width: sidebarWidth - 48, height: 1).fill()

    // Menu items
    let menuItems = [
        ("square.grid.2x2", "Dashboard"),
        ("doc.text.magnifyingglass", "Kontrolrapporter"),
        ("chart.bar.xaxis", "Analyser"),
        ("gearshape", "Indstillinger")
    ]

    let menuStartY = dividerY - 70
    let menuItemHeight: CGFloat = 60

    for (i, item) in menuItems.enumerated() {
        let itemY = menuStartY - CGFloat(i) * menuItemHeight

        if i == activeIndex {
            // Active background
            drawRoundedRect(context, rect: NSRect(x: 16, y: itemY - 6, width: sidebarWidth - 32, height: 50), radius: 10, fillColor: sidebarActive)
            // Active indicator bar
            medicalBlue.setFill()
            NSRect(x: 0, y: itemY - 6, width: 4, height: 50).fill()
            drawText(item.1, at: NSPoint(x: 60, y: itemY + 4), font: NSFont.systemFont(ofSize: 24, weight: .semibold), color: white)
        } else {
            drawText(item.1, at: NSPoint(x: 60, y: itemY + 4), font: NSFont.systemFont(ofSize: 24, weight: .regular), color: sidebarText)
        }
    }

    // Bottom: version
    drawText("Version 2.1.0", at: NSPoint(x: 40, y: 30), font: NSFont.systemFont(ofSize: 18), color: NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.25))
}

func drawWindowChrome(_ context: NSGraphicsContext) {
    // Top bar background
    let barHeight: CGFloat = 52
    let barY = CGFloat(height) - barHeight
    NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0).setFill()
    NSRect(x: 0, y: barY, width: CGFloat(width), height: barHeight).fill()

    // Traffic lights
    let dotY = barY + 18
    let dotRadius: CGFloat = 14
    for (i, color) in [
        NSColor(calibratedRed: 0.93, green: 0.33, blue: 0.30, alpha: 1.0),
        NSColor(calibratedRed: 0.98, green: 0.76, blue: 0.20, alpha: 1.0),
        NSColor(calibratedRed: 0.30, green: 0.78, blue: 0.35, alpha: 1.0)
    ].enumerated() {
        let dotX = 26 + CGFloat(i) * 32
        let path = NSBezierPath(ovalIn: NSRect(x: dotX, y: dotY, width: dotRadius, height: dotRadius))
        color.setFill()
        path.fill()
    }

    // Bottom border
    NSColor(calibratedRed: 0.85, green: 0.85, blue: 0.87, alpha: 1.0).setFill()
    NSRect(x: 0, y: barY, width: CGFloat(width), height: 1).fill()
}

// MARK: - Screenshot 1: Main Dashboard

func generateDashboard() {
    let rep = createBitmapContext()
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context

    // Background
    lightGray.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    // Window chrome
    drawWindowChrome(context)

    // Sidebar
    drawSidebar(context, activeIndex: 0)

    let contentX: CGFloat = 340
    let contentWidth = CGFloat(width) - contentX
    let topBarBottom = CGFloat(height) - 52

    // Header area with gradient
    let headerHeight: CGFloat = 200
    let headerY = topBarBottom - headerHeight
    drawGradientHeader(context, rect: NSRect(x: contentX, y: headerY, width: contentWidth, height: headerHeight))

    // Header text
    drawText("Dashboard", at: NSPoint(x: contentX + 60, y: headerY + 120), font: NSFont.systemFont(ofSize: 44, weight: .bold), color: white)
    drawText("Oversigt over kontrolresultater  |  Laegekapitlet Ferritslev", at: NSPoint(x: contentX + 60, y: headerY + 70), font: NSFont.systemFont(ofSize: 22, weight: .regular), color: NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.75))

    // Summary cards
    let cardY = headerY - 220
    let cardWidth: CGFloat = (contentWidth - 200) / 3
    let cardHeight: CGFloat = 180
    let cardStartX = contentX + 60

    let cards: [(String, String, NSColor)] = [
        ("286.585 kr", "Samlet potentiale", accentGreen),
        ("8", "Controlling-rapporter", medicalBlue),
        ("6.309", "Sikrede i praksis", accentOrange)
    ]

    for (i, card) in cards.enumerated() {
        let cx = cardStartX + CGFloat(i) * (cardWidth + 30)
        drawRoundedRect(context, rect: NSRect(x: cx, y: cardY, width: cardWidth, height: cardHeight), radius: 16, fillColor: white, shadowOffset: 6)

        // Color accent bar at top of card
        let gc = context.cgContext
        gc.saveGState()
        let barPath = NSBezierPath(roundedRect: NSRect(x: cx, y: cardY + cardHeight - 6, width: cardWidth, height: 6), xRadius: 0, yRadius: 0)
        card.2.setFill()
        barPath.fill()
        gc.restoreGState()

        // Value
        drawText(card.0, at: NSPoint(x: cx + 30, y: cardY + 70), font: NSFont.systemFont(ofSize: 48, weight: .bold), color: textDark)
        // Label
        drawText(card.1, at: NSPoint(x: cx + 30, y: cardY + 30), font: NSFont.systemFont(ofSize: 22, weight: .medium), color: textMedium)
    }

    // Recent reports section
    let sectionY = cardY - 80
    drawText("Seneste kontrolrapporter", at: NSPoint(x: cardStartX, y: sectionY), font: NSFont.systemFont(ofSize: 30, weight: .semibold), color: textDark)

    // Report list card
    let listY = sectionY - 400
    let listWidth = contentWidth - 120
    drawRoundedRect(context, rect: NSRect(x: cardStartX, y: listY, width: listWidth, height: 370), radius: 16, fillColor: white, shadowOffset: 4)

    let reports = [
        ("EKG (7156)", "51.798 kr", "Hoej"),
        ("Hb (7108)", "48.296 kr", "Hoej"),
        ("Spirometri (7113)", "43.210 kr", "Middel"),
        ("CRP (7120)", "38.564 kr", "Middel"),
        ("Urinstix (7108)", "32.190 kr", "Lav")
    ]

    // Table header
    let tableHeaderY = listY + 370 - 55
    NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.97, alpha: 1.0).setFill()
    NSRect(x: cardStartX, y: tableHeaderY, width: listWidth, height: 50).fill()

    drawText("Rapport", at: NSPoint(x: cardStartX + 30, y: tableHeaderY + 14), font: NSFont.systemFont(ofSize: 20, weight: .semibold), color: textMedium)
    drawText("Potentiale", at: NSPoint(x: cardStartX + 500, y: tableHeaderY + 14), font: NSFont.systemFont(ofSize: 20, weight: .semibold), color: textMedium)
    drawText("Prioritet", at: NSPoint(x: cardStartX + 800, y: tableHeaderY + 14), font: NSFont.systemFont(ofSize: 20, weight: .semibold), color: textMedium)

    for (i, report) in reports.enumerated() {
        let rowY = tableHeaderY - CGFloat(i + 1) * 60

        // Alternating row color
        if i % 2 == 0 {
            NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.99, alpha: 1.0).setFill()
            NSRect(x: cardStartX, y: rowY, width: listWidth, height: 56).fill()
        }

        drawText(report.0, at: NSPoint(x: cardStartX + 30, y: rowY + 16), font: NSFont.systemFont(ofSize: 22, weight: .medium), color: textDark)
        drawText(report.1, at: NSPoint(x: cardStartX + 500, y: rowY + 16), font: NSFont.systemFont(ofSize: 22, weight: .semibold), color: accentGreen)

        let priorityColor: NSColor = report.2 == "Hoej" ? accentRed : (report.2 == "Middel" ? accentOrange : accentGreen)
        // Priority badge
        let badgeX = cardStartX + 800
        drawRoundedRect(context, rect: NSRect(x: badgeX, y: rowY + 12, width: 90, height: 32), radius: 8, fillColor: priorityColor.withAlphaComponent(0.12))
        drawCenteredText(report.2, in: NSRect(x: badgeX, y: rowY + 12, width: 90, height: 32), font: NSFont.systemFont(ofSize: 18, weight: .semibold), color: priorityColor)
    }

    NSGraphicsContext.restoreGraphicsState()
    saveImage(rep, name: "screenshot_1.png")
}

// MARK: - Screenshot 2: Report View

func generateReportView() {
    let rep = createBitmapContext()
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context

    // Background
    lightGray.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    // Window chrome
    drawWindowChrome(context)

    // Sidebar
    drawSidebar(context, activeIndex: 1)

    let contentX: CGFloat = 340
    let contentWidth = CGFloat(width) - contentX
    let topBarBottom = CGFloat(height) - 52

    // Header
    let headerHeight: CGFloat = 180
    let headerY = topBarBottom - headerHeight
    drawGradientHeader(context, rect: NSRect(x: contentX, y: headerY, width: contentWidth, height: headerHeight))

    drawText("Kontrolrapporter", at: NSPoint(x: contentX + 60, y: headerY + 100), font: NSFont.systemFont(ofSize: 44, weight: .bold), color: white)
    drawText("Detaljeret oversigt over alle ydelseskontroludsaetninger", at: NSPoint(x: contentX + 60, y: headerY + 50), font: NSFont.systemFont(ofSize: 22, weight: .regular), color: NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.75))

    let cardStartX = contentX + 60
    let tableWidth = contentWidth - 120

    // Filter bar
    let filterY = headerY - 80
    drawRoundedRect(context, rect: NSRect(x: cardStartX, y: filterY, width: tableWidth, height: 56), radius: 12, fillColor: white, shadowOffset: 3)
    drawText("Soeg i rapporter...", at: NSPoint(x: cardStartX + 24, y: filterY + 16), font: NSFont.systemFont(ofSize: 22), color: textLight)

    // "Alle" filter chip
    drawRoundedRect(context, rect: NSRect(x: cardStartX + tableWidth - 320, y: filterY + 10, width: 80, height: 36), radius: 8, fillColor: medicalBlue)
    drawCenteredText("Alle", in: NSRect(x: cardStartX + tableWidth - 320, y: filterY + 10, width: 80, height: 36), font: NSFont.systemFont(ofSize: 18, weight: .medium), color: white)

    drawRoundedRect(context, rect: NSRect(x: cardStartX + tableWidth - 220, y: filterY + 10, width: 90, height: 36), radius: 8, fillColor: NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.96, alpha: 1.0))
    drawCenteredText("Hoej", in: NSRect(x: cardStartX + tableWidth - 220, y: filterY + 10, width: 90, height: 36), font: NSFont.systemFont(ofSize: 18, weight: .medium), color: textMedium)

    drawRoundedRect(context, rect: NSRect(x: cardStartX + tableWidth - 110, y: filterY + 10, width: 90, height: 36), radius: 8, fillColor: NSColor(calibratedRed: 0.94, green: 0.95, blue: 0.96, alpha: 1.0))
    drawCenteredText("Lav", in: NSRect(x: cardStartX + tableWidth - 110, y: filterY + 10, width: 90, height: 36), font: NSFont.systemFont(ofSize: 18, weight: .medium), color: textMedium)

    // Table card
    let tableY = filterY - 760
    let tableHeight: CGFloat = 740
    drawRoundedRect(context, rect: NSRect(x: cardStartX, y: tableY, width: tableWidth, height: tableHeight), radius: 16, fillColor: white, shadowOffset: 4)

    // Table header
    let thY = tableY + tableHeight - 60
    NSColor(calibratedRed: 0.95, green: 0.96, blue: 0.97, alpha: 1.0).setFill()
    let headerPath = NSBezierPath(roundedRect: NSRect(x: cardStartX, y: thY, width: tableWidth, height: 60), xRadius: 16, yRadius: 16)
    headerPath.fill()

    let cols: [(String, CGFloat)] = [
        ("Ydelse", 30),
        ("Ydelsesnr.", 400),
        ("Antal", 600),
        ("Praksis gns.", 800),
        ("Region gns.", 1050),
        ("Potentiale", 1300),
        ("Status", 1550)
    ]

    for col in cols {
        drawText(col.0, at: NSPoint(x: cardStartX + col.1, y: thY + 18), font: NSFont.systemFont(ofSize: 20, weight: .semibold), color: textMedium)
    }

    let rows: [(String, String, String, String, String, String, String)] = [
        ("EKG", "7156", "1.247", "8,4 pr. 100", "5,1 pr. 100", "51.798 kr", "Over"),
        ("Hb", "7108", "982", "6,6 pr. 100", "4,2 pr. 100", "48.296 kr", "Over"),
        ("Spirometri", "7113", "856", "5,7 pr. 100", "3,8 pr. 100", "43.210 kr", "Over"),
        ("CRP", "7120", "1.534", "10,3 pr. 100", "7,9 pr. 100", "38.564 kr", "Over"),
        ("Urinstix", "7108", "764", "5,1 pr. 100", "3,6 pr. 100", "32.190 kr", "Over"),
        ("INR", "7135", "423", "2,8 pr. 100", "2,1 pr. 100", "18.405 kr", "Margin"),
        ("Blodtryk 24t", "7112", "312", "2,1 pr. 100", "1,6 pr. 100", "15.890 kr", "Margin"),
        ("Glukose", "7136", "689", "4,6 pr. 100", "3,4 pr. 100", "22.430 kr", "Over"),
        ("BNP", "7190", "198", "1,3 pr. 100", "0,9 pr. 100", "8.756 kr", "Margin"),
        ("D-vitamin", "7145", "534", "3,6 pr. 100", "3,2 pr. 100", "7.046 kr", "Under")
    ]

    let rowHeight: CGFloat = 64
    for (i, row) in rows.enumerated() {
        let ry = thY - CGFloat(i + 1) * rowHeight

        if i % 2 == 0 {
            NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.99, alpha: 1.0).setFill()
            NSRect(x: cardStartX, y: ry, width: tableWidth, height: rowHeight).fill()
        }

        let fontSize: CGFloat = 21
        drawText(row.0, at: NSPoint(x: cardStartX + 30, y: ry + 20), font: NSFont.systemFont(ofSize: fontSize, weight: .medium), color: textDark)
        drawText(row.1, at: NSPoint(x: cardStartX + 400, y: ry + 20), font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular), color: textMedium)
        drawText(row.2, at: NSPoint(x: cardStartX + 600, y: ry + 20), font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular), color: textDark)
        drawText(row.3, at: NSPoint(x: cardStartX + 800, y: ry + 20), font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular), color: textDark)
        drawText(row.4, at: NSPoint(x: cardStartX + 1050, y: ry + 20), font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular), color: textMedium)
        drawText(row.5, at: NSPoint(x: cardStartX + 1300, y: ry + 20), font: NSFont.systemFont(ofSize: fontSize, weight: .bold), color: accentGreen)

        let statusColor: NSColor
        let statusBgColor: NSColor
        switch row.6 {
        case "Over": statusColor = accentRed; statusBgColor = accentRed.withAlphaComponent(0.10)
        case "Margin": statusColor = accentOrange; statusBgColor = accentOrange.withAlphaComponent(0.10)
        default: statusColor = accentGreen; statusBgColor = accentGreen.withAlphaComponent(0.10)
        }
        drawRoundedRect(context, rect: NSRect(x: cardStartX + 1550, y: ry + 16, width: 100, height: 32), radius: 8, fillColor: statusBgColor)
        drawCenteredText(row.6, in: NSRect(x: cardStartX + 1550, y: ry + 16, width: 100, height: 32), font: NSFont.systemFont(ofSize: 17, weight: .semibold), color: statusColor)
    }

    NSGraphicsContext.restoreGraphicsState()
    saveImage(rep, name: "screenshot_2.png")
}

// MARK: - Screenshot 3: Analysis Detail

func generateAnalysisDetail() {
    let rep = createBitmapContext()
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context

    // Background
    lightGray.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    // Window chrome
    drawWindowChrome(context)

    // Sidebar
    drawSidebar(context, activeIndex: 2)

    let contentX: CGFloat = 340
    let contentWidth = CGFloat(width) - contentX
    let topBarBottom = CGFloat(height) - 52

    // Header
    let headerHeight: CGFloat = 180
    let headerY = topBarBottom - headerHeight
    drawGradientHeader(context, rect: NSRect(x: contentX, y: headerY, width: contentWidth, height: headerHeight))

    drawText("Analyser", at: NSPoint(x: contentX + 60, y: headerY + 100), font: NSFont.systemFont(ofSize: 44, weight: .bold), color: white)
    drawText("Afvigelse fra regionsgennemsnit pr. ydelse", at: NSPoint(x: contentX + 60, y: headerY + 50), font: NSFont.systemFont(ofSize: 22, weight: .regular), color: NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.75))

    let cardStartX = contentX + 60
    let chartWidth = contentWidth - 120

    // Chart card
    let chartCardY: CGFloat = 100
    let chartCardHeight = headerY - chartCardY - 40
    drawRoundedRect(context, rect: NSRect(x: cardStartX, y: chartCardY, width: chartWidth, height: chartCardHeight), radius: 16, fillColor: white, shadowOffset: 6)

    // Chart title
    let chartTitleY = chartCardY + chartCardHeight - 70
    drawText("Afvigelse fra regionsgennemsnit (%)", at: NSPoint(x: cardStartX + 40, y: chartTitleY), font: NSFont.systemFont(ofSize: 26, weight: .semibold), color: textDark)
    drawText("Positive vaerdier = praksis ligger over gennemsnittet", at: NSPoint(x: cardStartX + 40, y: chartTitleY - 35), font: NSFont.systemFont(ofSize: 19), color: textMedium)

    // Chart area
    let chartLeft = cardStartX + 220
    let chartBottom = chartCardY + 80
    let chartTop = chartTitleY - 60
    let chartRight = cardStartX + chartWidth - 80
    let chartAreaWidth = chartRight - chartLeft
    let chartAreaHeight = chartTop - chartBottom

    // Y-axis labels (ydelser)
    let ydelser: [(String, Double)] = [
        ("EKG (7156)", 64.7),
        ("Hb (7108)", 57.1),
        ("Spirometri (7113)", 50.0),
        ("CRP (7120)", 30.4),
        ("Urinstix (7108)", 41.7),
        ("INR (7135)", 33.3),
        ("Blodtryk 24t (7112)", 31.3),
        ("Glukose (7136)", 35.3),
        ("BNP (7190)", 44.4),
        ("D-vitamin (7145)", 12.5)
    ]

    let barHeight: CGFloat = (chartAreaHeight - 40) / CGFloat(ydelser.count)
    let barGap: CGFloat = 8
    let maxVal = 70.0

    // Zero line and grid
    let zeroX = chartLeft

    // Grid lines
    for pct in stride(from: 0, through: 70, by: 10) {
        let x = zeroX + CGFloat(Double(pct) / maxVal) * chartAreaWidth
        NSColor(calibratedRed: 0.92, green: 0.93, blue: 0.94, alpha: 1.0).setFill()
        NSRect(x: x, y: chartBottom, width: 1, height: chartAreaHeight).fill()

        // Grid label
        drawText("\(pct)%", at: NSPoint(x: x - 15, y: chartBottom - 30), font: NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular), color: textLight)
    }

    // Zero line (bold)
    NSColor(calibratedRed: 0.75, green: 0.77, blue: 0.80, alpha: 1.0).setFill()
    NSRect(x: zeroX, y: chartBottom, width: 2, height: chartAreaHeight).fill()

    // Bars
    for (i, ydelse) in ydelser.enumerated() {
        let barY = chartTop - CGFloat(i + 1) * barHeight + barGap / 2
        let barW = CGFloat(ydelse.1 / maxVal) * chartAreaWidth
        let actualBarHeight = barHeight - barGap

        // Gradient-like bar color based on value
        let barColor: NSColor
        if ydelse.1 > 50 {
            barColor = accentRed
        } else if ydelse.1 > 30 {
            barColor = accentOrange
        } else {
            barColor = medicalBlue
        }

        // Bar
        drawRoundedRect(context, rect: NSRect(x: zeroX, y: barY, width: barW, height: actualBarHeight), radius: 6, fillColor: barColor.withAlphaComponent(0.85))

        // Value label at end of bar
        let valStr = String(format: "+%.1f%%", ydelse.1)
        drawText(valStr, at: NSPoint(x: zeroX + barW + 10, y: barY + (actualBarHeight - 22) / 2), font: NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold), color: barColor)

        // Y-axis label
        drawText(ydelse.0, at: NSPoint(x: cardStartX + 30, y: barY + (actualBarHeight - 20) / 2), font: NSFont.systemFont(ofSize: 18, weight: .medium), color: textDark, maxWidth: 190)
    }

    // Legend
    let legendY = chartCardY + 25
    let legendItems: [(String, NSColor)] = [
        ("Over 50% afvigelse", accentRed),
        ("30-50% afvigelse", accentOrange),
        ("Under 30% afvigelse", medicalBlue)
    ]

    var legendX = cardStartX + 40.0
    for item in legendItems {
        let dotRect = NSRect(x: legendX, y: legendY + 2, width: 16, height: 16)
        drawRoundedRect(context, rect: dotRect, radius: 4, fillColor: item.1)
        drawText(item.0, at: NSPoint(x: legendX + 24, y: legendY), font: NSFont.systemFont(ofSize: 18), color: textMedium)
        legendX += 250
    }

    NSGraphicsContext.restoreGraphicsState()
    saveImage(rep, name: "screenshot_3.png")
}

// MARK: - Main

print("Generating App Store screenshots (2880x1800)...")
generateDashboard()
generateReportView()
generateAnalysisDetail()
print("Done! All 3 screenshots generated.")
