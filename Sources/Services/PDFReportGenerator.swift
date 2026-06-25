import SwiftUI
import UIKit

/// Renders an inspection into a US-Letter PDF. The car diagram (with markers)
/// is rasterized from the very same SwiftUI view shown on screen, so the
/// printed marks line up exactly with what the customer saw.
@MainActor
enum PDFReportGenerator {

    static func generate(for inspection: Inspection, profile: BusinessProfile?) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let diagramImage = renderDiagram(for: inspection)
        let signatureImage = FileStorage.image(atRelative: inspection.signaturePath)
        let logoImage = FileStorage.image(atRelative: profile?.logoPath)
        let isPro = profile?.isPro ?? false
        let businessName = (profile?.name.isEmpty == false) ? profile!.name : "DentProof Inspection"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DentProof-\(shortID(inspection)).pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                var d = PageDrawer(cg: ctx.cgContext, pageRect: pageRect, margin: 44)
                d.beginPage(ctx)

                d.header(name: businessName, logo: logoImage, date: inspection.signedAt ?? inspection.createdAt)
                d.spacer(10)
                d.vehicleBlock(inspection)
                d.spacer(14)

                if let diagramImage {
                    d.ensureSpace(for: 360, ctx: ctx)
                    d.sectionTitle("Pre-existing condition")
                    d.image(diagramImage, maxHeight: 330)
                    d.spacer(8)
                }

                d.spacer(6)
                d.sectionTitle("Marks (\(inspection.marks.count))")
                if inspection.marks.isEmpty {
                    d.body("No pre-existing damage recorded. The vehicle was documented as clean before service.")
                } else {
                    for mark in inspection.marksSorted {
                        d.markRow(mark, ctx: ctx)
                    }
                }

                d.spacer(16)
                d.signatureBlock(inspection: inspection, signature: signatureImage, ctx: ctx)

                if !isPro {
                    d.footerWatermark("Made with DentProof")
                }
            }
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Diagram rasterization

    private static func renderDiagram(for inspection: Inspection) -> UIImage? {
        let markers = inspection.marksSorted.map { (index: $0.index, x: $0.x, y: $0.y) }
        let diagramWidth: CGFloat = 300
        let diagramHeight = diagramWidth / kDiagramAspect   // same aspect as on-screen
        let view = DiagramWithMarkers(style: inspection.bodyStyle, markers: markers, markerDiameter: 24)
            .frame(width: diagramWidth, height: diagramHeight)
            .background(Color.white)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        return renderer.uiImage
    }

    private static func shortID(_ inspection: Inspection) -> String {
        String(inspection.id.uuidString.prefix(8))
    }
}

// MARK: - Page drawing helper

private struct PageDrawer {
    let cg: CGContext
    let pageRect: CGRect
    let margin: CGFloat
    var y: CGFloat = 0
    private var contentWidth: CGFloat { pageRect.width - margin * 2 }
    private var bottomLimit: CGFloat { pageRect.height - margin - 16 }

    private let ink = UIColor(red: 0x1D/255, green: 0x1D/255, blue: 0x1E/255, alpha: 1)
    private let inkSecondary = UIColor(red: 0x7A/255, green: 0x79/255, blue: 0x77/255, alpha: 1)
    private let clayDeep = UIColor(red: 0xB5/255, green: 0x61/255, blue: 0x3D/255, alpha: 1)
    private let clay = UIColor(red: 0xD9/255, green: 0x7D/255, blue: 0x56/255, alpha: 1)
    private let hairline = UIColor(red: 0xDB/255, green: 0xDA/255, blue: 0xD7/255, alpha: 1)

    mutating func beginPage(_ ctx: UIGraphicsPDFRendererContext) {
        ctx.beginPage()
        y = margin
    }

    mutating func spacer(_ h: CGFloat) { y += h }

    mutating func ensureSpace(for height: CGFloat, ctx: UIGraphicsPDFRendererContext) {
        if y + height > bottomLimit { beginPage(ctx) }
    }

    // MARK: Components

    mutating func header(name: String, logo: UIImage?, date: Date) {
        let logoSize: CGFloat = 40
        var textX = margin
        if let logo {
            let rect = CGRect(x: margin, y: y, width: logoSize, height: logoSize)
            logo.aspectFit(in: rect).draw(in: rect)
            textX = margin + logoSize + 12
        }
        draw(name, font: .systemFont(ofSize: 18, weight: .semibold), color: ink,
             at: CGPoint(x: textX, y: y + 2))
        draw(DP.full(date), font: .systemFont(ofSize: 10), color: inkSecondary,
             at: CGPoint(x: textX, y: y + 24))
        y += logoSize + 6
        rule()
    }

    mutating func vehicleBlock(_ inspection: Inspection) {
        let left = [
            ("VEHICLE", inspection.vehicleTitle),
            ("COLOR", inspection.vehicleColor.isEmpty ? "—" : inspection.vehicleColor),
            ("PLATE", inspection.vehiclePlate ?? "—")
        ]
        let right = [
            ("CUSTOMER", inspection.customerName.isEmpty ? "—" : inspection.customerName),
            ("PHONE", inspection.customerPhone ?? "—"),
            ("BODY STYLE", inspection.bodyStyle.displayName)
        ]
        let colW = contentWidth / 2
        let startY = y
        var ly = y
        for (label, value) in left {
            draw(label, font: .systemFont(ofSize: 8, weight: .semibold), color: inkSecondary,
                 at: CGPoint(x: margin, y: ly))
            draw(value, font: .systemFont(ofSize: 12), color: ink,
                 at: CGPoint(x: margin, y: ly + 10))
            ly += 30
        }
        var ry = startY
        for (label, value) in right {
            draw(label, font: .systemFont(ofSize: 8, weight: .semibold), color: inkSecondary,
                 at: CGPoint(x: margin + colW, y: ry))
            draw(value, font: .systemFont(ofSize: 12), color: ink,
                 at: CGPoint(x: margin + colW, y: ry + 10))
            ry += 30
        }
        y = max(ly, ry)
    }

    mutating func sectionTitle(_ text: String) {
        draw(text, font: .systemFont(ofSize: 14, weight: .semibold), color: ink,
             at: CGPoint(x: margin, y: y))
        y += 22
    }

    mutating func body(_ text: String) {
        let h = draw(text, font: .systemFont(ofSize: 11), color: inkSecondary,
                     in: CGRect(x: margin, y: y, width: contentWidth, height: 200))
        y += h + 4
    }

    mutating func image(_ image: UIImage, maxHeight: CGFloat) {
        let aspect = image.size.width / image.size.height
        var h = maxHeight
        var w = h * aspect
        if w > contentWidth { w = contentWidth; h = w / aspect }
        let x = margin + (contentWidth - w) / 2
        image.draw(in: CGRect(x: x, y: y, width: w, height: h))
        y += h
    }

    mutating func markRow(_ mark: DamageMark, ctx: UIGraphicsPDFRendererContext) {
        let thumbSize: CGFloat = 46
        let rowHeight: CGFloat = max(44, mark.photos.isEmpty ? 44 : thumbSize + 14)
        ensureSpace(for: rowHeight + 6, ctx: ctx)

        // Numbered clay disc
        let disc = CGRect(x: margin, y: y, width: 22, height: 22)
        cg.setFillColor(clay.cgColor)
        cg.fillEllipse(in: disc)
        drawCentered("\(mark.index)", font: .boldSystemFont(ofSize: 11), color: .white, in: disc)

        let textX = margin + 32
        let title = mark.type.displayName +
            (mark.locationLabel.isEmpty ? "" : " · \(mark.locationLabel)")
        draw(title, font: .systemFont(ofSize: 12, weight: .medium), color: ink,
             at: CGPoint(x: textX, y: y + 1))
        if let note = mark.note, !note.isEmpty {
            draw(note, font: .systemFont(ofSize: 10), color: inkSecondary,
                 at: CGPoint(x: textX, y: y + 16))
        }

        // Thumbnails
        if !mark.photos.isEmpty {
            var tx = textX
            let ty = y + 24
            for photo in mark.photos.prefix(6) {
                if let img = FileStorage.image(atRelative: photo.path) {
                    let rect = CGRect(x: tx, y: ty, width: thumbSize, height: thumbSize)
                    img.aspectFill(in: rect).draw(in: rect)
                    cg.setStrokeColor(hairline.cgColor)
                    cg.setLineWidth(0.5)
                    cg.stroke(rect)
                    tx += thumbSize + 6
                }
            }
        }
        y += rowHeight
        rule(faint: true)
    }

    mutating func signatureBlock(inspection: Inspection, signature: UIImage?, ctx: UIGraphicsPDFRendererContext) {
        ensureSpace(for: 130, ctx: ctx)
        sectionTitle("Signature")
        if let signature {
            let maxW: CGFloat = 220, maxH: CGFloat = 70
            let aspect = signature.size.width / max(signature.size.height, 1)
            var w = maxH * aspect, h = maxH
            if w > maxW { w = maxW; h = w / aspect }
            signature.draw(in: CGRect(x: margin, y: y, width: w, height: h))
            y += h + 4
        }
        cg.setStrokeColor(hairline.cgColor)
        cg.setLineWidth(0.5)
        cg.move(to: CGPoint(x: margin, y: y)); cg.addLine(to: CGPoint(x: margin + 220, y: y)); cg.strokePath()
        y += 4

        let name = inspection.customerName.isEmpty ? "Customer" : inspection.customerName
        draw(name, font: .systemFont(ofSize: 11, weight: .medium), color: ink,
             at: CGPoint(x: margin, y: y))
        y += 16
        if let signedAt = inspection.signedAt {
            draw("Signed \(DP.full(signedAt))", font: .systemFont(ofSize: 9), color: inkSecondary,
                 at: CGPoint(x: margin, y: y))
            y += 12
        }
        if inspection.hasLocation, let lat = inspection.latitude, let lon = inspection.longitude {
            draw("Location \(DP.coordinate(lat: lat, lon: lon))",
                 font: .systemFont(ofSize: 9), color: inkSecondary,
                 at: CGPoint(x: margin, y: y))
            y += 12
        }
    }

    func footerWatermark(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: inkSecondary
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let point = CGPoint(x: (pageRect.width - size.width) / 2,
                            y: pageRect.height - margin + 2)
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    // MARK: Primitives

    private mutating func rule(faint: Bool = false) {
        y += faint ? 4 : 8
        cg.setStrokeColor((faint ? hairline.withAlphaComponent(0.6) : hairline).cgColor)
        cg.setLineWidth(0.5)
        cg.move(to: CGPoint(x: margin, y: y))
        cg.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        cg.strokePath()
        y += faint ? 6 : 10
    }

    @discardableResult
    private func draw(_ text: String, font: UIFont, color: UIColor, at point: CGPoint) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        (text as NSString).draw(at: point, withAttributes: attrs)
        return font.lineHeight
    }

    @discardableResult
    private func draw(_ text: String, font: UIFont, color: UIColor, in rect: CGRect) -> CGFloat {
        let para = NSMutableParagraphStyle(); para.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: para]
        let bounding = (text as NSString).boundingRect(
            with: CGSize(width: rect.width, height: rect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil)
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading],
                                attributes: attrs, context: nil)
        return ceil(bounding.height)
    }

    private func drawCentered(_ text: String, font: UIFont, color: UIColor, in rect: CGRect) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attrs)
        let point = CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)
        (text as NSString).draw(at: point, withAttributes: attrs)
    }
}

// MARK: - UIImage fit helpers

private extension UIImage {
    func aspectFit(in rect: CGRect) -> UIImage {
        let aspect = size.width / max(size.height, 1)
        var w = rect.width, h = rect.width / aspect
        if h > rect.height { h = rect.height; w = h * aspect }
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(x: (rect.width - w) / 2, y: (rect.height - h) / 2, width: w, height: h))
        }
    }

    func aspectFill(in rect: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        return renderer.image { _ in
            let aspect = size.width / max(size.height, 1)
            var w = rect.width, h = rect.width / aspect
            if h < rect.height { h = rect.height; w = h * aspect }
            draw(in: CGRect(x: (rect.width - w) / 2, y: (rect.height - h) / 2, width: w, height: h))
        }
    }
}
