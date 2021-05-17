//
//  QRGenerator.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 16/05/2021.
//

import Foundation
import OSLog
import QRCodeGenerator
import UIKit

class QRGenerator {

    private static let HTML_BEGIN = """
    <!doctype html><html><head><meta charset="utf-8" /><style>
    body,html,p,span{margin:0;font-family:-apple-system,sans-serif}
    .page{margin:0;box-sizing:border-box;padding:1cm;display:grid;
    width:100%;height:120vh;grid-template:repeat(4,1fr)/repeat(3,1fr);gap:16px}
    .item{display:grid;grid-template-rows:min-content min-content auto;gap:0;
    text-align:center;overflow:hidden;border:1px solid #c4c4c4;padding:8px}
    .item>p{font-weight:700;font-size:large;margin-bottom:2px}
    .item>.loc{font-size:small}.item>.img{min-width:0;min-height:0;margin:8px}
    .item>.img>svg{display:block;width:100%;height:100%}
    .item>.code{font-family:ui-monospace,monospace;font-size:small}
    </style></head><body>
    """

    private static let HTML_END = "</body></html>"

    struct Model {
        var code: String
        var box: String?
        var location: String?
    }

    private let logger = Logger.qrGenerator
    private let queue = DispatchQueue(label: "com.przambrozy.iteminventory.qrgenerator.queue", qos: .userInitiated)

    /// Generate SVG for a given code
    /// - Note: The returned string starts with `<svg` and ends with `</svg>`
    private func codeToSVG(_ code: String, ecl: QRCodeECC = .quartile) -> String? {
        do {
            let qr = try QRCode.encode(text: code, ecl: ecl)
            let svg = qr.toSVGString(border: 0)
            if let beginning = svg.range(of: "<svg")?.lowerBound {
                return String(svg[beginning..<svg.endIndex])
            }
        } catch {
            logger.error("Cannot generate a QR code for code: \(code): \(error.localizedDescription)")
        }
        return nil
    }

    /// Create a div for a single box
    private func boxToDiv(_ box: Model) -> String {
        var html = #"<div class="item"><p>"#
        html += box.box ?? "&nbsp;"
        if let location = box.location {
            html += "</p><span class=\"loc\">Location: \(location)"
        } else {
            html += "</p><span class=\"loc\">&nbsp;"
        }
        html += #"</span><div class="img">"#
        if let svg = codeToSVG(box.code) {
            html += svg
        }
        html += "</div><span class=\"code\">\(box.code)</span></div>"
        return html
    }

    /// Create a page for up to 12 boxes
    private func boxesToPage(_ boxes: [Model], isLast: Bool = true) -> String {
        //let style = isLast ? "" : #"style="page-break-after: always;""#
        var html = #"<div class="page"><div class="break"></div>"#
        for box in boxes {
            html += boxToDiv(box)
        }
        html += "</div>"
        return html
    }

    private func createHTML(_ boxes: [Model]) -> String {
        let pageBoxes = boxes.chunked(into: 12)

        var html = Self.HTML_BEGIN
        for (index, page) in pageBoxes.enumerated() {
            html += boxesToPage(page, isLast: index == pageBoxes.endIndex - 1)
        }
        html += Self.HTML_END
        return html
    }

    private func toPDF(_ html: String) {
        print("PRINTING HTML\n", html)
        let formatter = UIMarkupTextPrintFormatter(markupText: html)

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)


        // A4 page
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        renderer.setValue(page, forKey: "paperRect")
        renderer.setValue(page, forKey: "printableRect")


        let pdfData = NSMutableData()

        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)


        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("printable.pdf")
        try? pdfData.write(to: url, options: [])

        print("URL: ", url)

    }

    private func createHTML2(_ boxes: [Model]) -> [String] {
        boxes
            .chunked(into: 12)
            .map { box in
                Self.HTML_BEGIN + #"<div class="page">"# + box.map { boxToDiv($0) }.joined() + "</div>" + Self.HTML_END
            }
    }

    private func toPDF2(_ pages: [String]) {

        // Setup renderer
        let renderer = UIPrintPageRenderer()

        // A4 page
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        renderer.setValue(page, forKey: "paperRect")
        renderer.setValue(page, forKey: "printableRect")

        pages.enumerated().forEach { (index, page) in
            let formatter = UIMarkupTextPrintFormatter(markupText: page)
            formatter.maximumContentHeight = 841.8
            renderer.addPrintFormatter(formatter, startingAtPageAt: index)
        }




        let pdfData = NSMutableData()

        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)


        for i in 0..<pages.count {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("printable.pdf")
        try? pdfData.write(to: url, options: [])

        print("URL: ", url)

    }

    init() {

        let example: [Model] = [
            .init(code: "S-0000001", box: "One", location: "Loc1"),
            .init(code: "S-0000002", box: "On2", location: "Loc2"),
            .init(code: "S-0000003", box: "On3", location: "Loc3"),
            .init(code: "S-0000004", box: "On4", location: "Loc4"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: nil, location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: nil),
            .init(code: "S-0000005", box: nil, location: nil),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-000PAG2", box: "Strona druga", location: "Loc1"),
            .init(code: "S-0000002", box: "On2", location: "Loc2"),
            .init(code: "S-0000003", box: "On3", location: "Loc3"),
            .init(code: "S-0000004", box: "On4", location: "Loc4"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: nil, location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: nil),
            .init(code: "S-0000005", box: nil, location: nil),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
            .init(code: "S-STR3", box: "Strona trzecia", location: "Loc5"),
            .init(code: "S-0000005", box: "On5", location: "Loc5"),
        ]

        let html = createHTML2(example)
        toPDF2(html)
    }
    
}


extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
