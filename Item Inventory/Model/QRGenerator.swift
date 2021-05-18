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

class QRGenerator: ObservableObject {

    private static let htmlBegin = """
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
    </style></head><body><div class="page">
    """

    private static let htmlEnd = "</div></body></html>"

    struct Box {
        var code: String
        var name: String?
        var location: String?
    }

    private let logger = Logger.qrGenerator
    private let queue = DispatchQueue(label: "com.przambrozy.iteminventory.qrgenerator.queue", qos: .userInitiated)

    // State
    @Published var isGenerating: Bool = false
    @Published var url: URL?

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
    private func boxToDiv(_ box: Box) -> String {
        var html = #"<div class="item"><p>"# + (box.name ?? "&nbsp;")
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

    /// Create a page HTML from a set of boxes
    private func createHTML(_ boxes: [Box]) -> [String] {
        boxes
            .chunked(into: 12)
            .map { page in
                Self.htmlBegin + page.map { boxToDiv($0) }.joined() + Self.htmlEnd
            }
    }

    /// Creata a PDF file from the given HTML pages, one HTML string per page
    private func createFile(_ pages: [String], filename: String = "codes.pdf") -> URL {

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

        for index in 0..<pages.count {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: index, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext()

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(filename)
        try? pdfData.write(to: url, options: [])

        return url

    }

    /// Generate a PDF with box QR codes
    func generate(_ boxes: [Box]) {
        isGenerating = true
        url = nil
        queue.async {
            let pages = self.createHTML(boxes)
            DispatchQueue.main.async {
                let url = self.createFile(pages)
                self.isGenerating = false
                self.url = url
            }
        }
    }

    /// Delete the PDF file from the disk
    func delete() {
        if let url = url {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                logger.warning("Cannot delete file at url \(url): \(error.localizedDescription)")
            }
        }
    }

}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
