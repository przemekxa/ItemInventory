//
//  BoxSearchView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI
import AVFoundation

struct BoxSearchView: View {

    struct Result {
        var mode: BoxSearchCapsuleView.Mode
        var name: String?
        var qrCode: String?
    }

    @Environment(\.storage)
    private var storage

    @Environment(\.presentationMode)
    private var presentationMode

    @State private var successPlayer: AVAudioPlayer?
    @State private var errorPlayer: AVAudioPlayer?

    var box: Box

    @State private var isActive = true

    @State private var result: Result?

    var body: some View {
        ZStack {
            QRBarcodeView(objectTypes: [.qr, .ean8, .ean13, .upc],
                          active: $isActive,
                          handler: handleResult(result:))
                .ignoresSafeArea(.all, edges: .all)

            VStack(spacing: 0) {
                Spacer()
                if let result = result {
                    BoxSearchCapsuleView(mode: result.mode, name: result.name, qrCode: result.qrCode) {
                        withAnimation {
                            self.result = nil
                            isActive = true
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring())
                }
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Close")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(16.0)
                        .background(
                            RoundedRectangle(cornerRadius: 32.0, style: .continuous)
                                .fill(Color.blue)
                                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 0)
                        )
                        .padding([.horizontal, .bottom], 16.0)
                        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 0)
                }
                .frame(alignment: .bottom)
            }

        }
        .onAppear {
            prepareAudio()
        }
        .onDisappear {
            successPlayer?.stop()
            errorPlayer?.stop()
        }
    }

    private func handleResult(result: QRBarcodeView.Result) {
        isActive = false

        switch result {
        case .success(let code, _):
            if box.qrCode == code {
                successPlayer?.play()
                self.result = Result(mode: .correctBox, name: box.name ?? "?", qrCode: code)
            } else if let identifier = Box.qrCodeToInt(code), let box = storage.box(with: identifier) {
                errorPlayer?.play()
                self.result = Result(mode: .wrongBox, name: box.name ?? "?", qrCode: code)
            } else {
                errorPlayer?.play()
                self.result = Result(mode: .boxNotFound, name: nil, qrCode: nil)
            }
        case .error:
            errorPlayer?.play()
            self.result = Result(mode: .error, name: nil, qrCode: nil)
        }
    }

    /// Prepare the players for playing
    private func prepareAudio() {
        if let successData = NSDataAsset(name: "success")?.data {
            successPlayer = try? AVAudioPlayer(data: successData)
            successPlayer?.prepareToPlay()
        }
        if let errorData = NSDataAsset(name: "error")?.data {
            errorPlayer = try? AVAudioPlayer(data: errorData)
            errorPlayer?.prepareToPlay()
        }
    }
}

struct BoxSearchView_Previews: PreviewProvider {
    static var previews: some View {
        BoxSearchView(box: Box())
    }
}
