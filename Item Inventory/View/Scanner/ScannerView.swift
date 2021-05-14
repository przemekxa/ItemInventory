//
//  VisualSearchView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 14/05/2021.
//

import SwiftUI

protocol ScannerViewDelegate: AnyObject {
    func showBox(_ box: Box)
    func showItem(_ item: Item)
}

struct ScannerView: View {

    @Environment(\.storage)
    private var storage

    @State private var isActive = true

    @State private var result: (BoxSearchCapsuleView.Mode, String?, String?, String?)?

    @State private var box: Box?

    weak var delegate: ScannerViewDelegate?

    
    var body: some View {
        ZStack {
            QRBarcodeView(objectTypes: [.qr, .ean8, .ean13, .upc],
                          active: $isActive,
                          handler: handleResult(result:))
                .ignoresSafeArea(.all, edges: .all)

            VStack(spacing: 0) {
                Spacer()
                if let (mode, name, code, codeName) = result {
                    BoxSearchCapsuleView(mode: mode, name: name, qrCode: code, codeName: codeName) {
                        withAnimation {
                            result = nil
                            isActive = true
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring())
                }
            }

        }
        .navigationTitle("Scanner")
    }

    private func handleResult(result: QRBarcodeView.Result) {
        isActive = false
        switch result {
        case .success(let code, let type):
            let typeString = type == .qr ? "QR Code" : "Barcode"

            if let box = findBox(code) {
                delegate?.showBox(box)
            } else if let item = storage.item(with: code) {
                delegate?.showItem(item)
            } else {
                self.result = (.notFound, nil, code, typeString)
            }
        case .error:
            self.result = (.error, nil, nil, nil)
        }
    }

    private func findBox(_ code: String) -> Box? {
        let regex = try! NSRegularExpression(pattern: #"S-\d{8}"#)
        if regex.firstMatch(in: code,
                            options: [],
                            range: NSRange(location: 0, length: code.utf16.count)) != nil {

            let startIndex = code.index(code.startIndex, offsetBy: 2)
            let endIndex = code.index(code.startIndex, offsetBy: 9)
            let id = Int(code[startIndex...endIndex])!

            return storage.box(with: id)
        }
        return nil
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
