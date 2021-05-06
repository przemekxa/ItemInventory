//
//  BoxSearchView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI
import AVFoundation

struct BoxSearchView: View {

    @Environment(\.storage)
    private var storage

    @Environment(\.presentationMode)
    private var presentationMode

    @State private var successPlayer: AVAudioPlayer?
    @State private var errorPlayer: AVAudioPlayer?

    var box: Box

    @State private var isActive = true

    @State private var result: (BoxSearchCapsuleView.Mode, String?, String?)?

    var body: some View {
        ZStack {
            QRBarcodeView(objectTypes: [.qr, .ean8, .ean13, .upc],
                          active: $isActive,
                          handler: handleResult(result:))
                .ignoresSafeArea(.all, edges: .all)

            VStack(spacing: 0) {
                Spacer()
                if let (mode, name, qrCode) = result {
                    BoxSearchCapsuleView(mode: mode, name: name, qrCode: qrCode) {
                        withAnimation {
                            result = nil
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
        // TODO: Play audio
        switch result {
        case .success(let code):
            if box.qrCode == code {
                successPlayer?.play()
                self.result = (.correctBox, box.name ?? "?", code)
            } else if let identifier = Box.qrCodeToInt(code), let box = storage.box(with: identifier) {
                errorPlayer?.play()
                self.result = (.wrongBox, box.name ?? "?", code)
            } else {
                errorPlayer?.play()
                self.result = (.boxNotFound, nil, nil)
            }
        case .error:
            errorPlayer?.play()
            self.result = (.error, nil, nil)
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
