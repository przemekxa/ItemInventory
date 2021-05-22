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

    struct Result {
        var mode: BoxSearchCapsuleView.Mode
        var name: String?
        var code: String?
        var codeName: String?
    }

    @Environment(\.storage)
    private var storage

    @State private var isActive = true

    @State private var result: Result?

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
                if let result = result {
                    BoxSearchCapsuleView(mode: result.mode,
                                         name: result.name,
                                         qrCode: result.code,
                                         codeName: result.codeName) {
                        withAnimation {
                            self.result = nil
                            isActive = true
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring())
                }
            }

        }
        .onAppear {
            isActive = true
            result = nil
            // SwiftUI tab bar title bug workaround
            NotificationCenter.default.post(name: Navigation.updateTabBar, object: nil)
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
                self.result = Result(mode: .notFound, name: nil, code: code, codeName: typeString)
            }
        case .error:
            self.result = Result(mode: .error, name: nil, code: nil, codeName: nil)
        }
    }

    private func findBox(_ code: String) -> Box? {

        if let regex = try? NSRegularExpression(pattern: #"S-\d{8}"#),
           regex.firstMatch(in: code,
                            options: [],
                            range: NSRange(location: 0, length: code.utf16.count)) != nil {

            let startIndex = code.index(code.startIndex, offsetBy: 2)
            let endIndex = code.index(code.startIndex, offsetBy: 9)
            let identifier = Int(code[startIndex...endIndex])!

            return storage.box(with: identifier)
        }
        return nil
    }
}

struct ScannerView_Previews: PreviewProvider {
    static var previews: some View {
        ScannerView()
    }
}
