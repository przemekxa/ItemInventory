//
//  QRSettingsView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 16/05/2021.
//

import SwiftUI

struct QRSettingsView: View {

    @Environment(\.storage)
    private var storage

    @FetchRequest(entity: Box.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Box.name, ascending: true)])
    private var boxes: FetchedResults<Box>

    @State private var futureCount = 0

    @State private var selectedBoxes = Set<Box>()

    @ObservedObject
    private var generator = QRGenerator()

    var body: some View {
        List {
            Section(header: Text("Codes for future boxes")) {
                Stepper("Future codes: \(futureCount)",
                        value: $futureCount,
                        in: 0...120)
            }
            Section(header: Text("Existing boxes")) {
                ForEach(boxes) { box in
                    HStack(spacing: 12.0) {
                        Image(systemName: selectedBoxes.contains(box) ? "checkmark.circle.fill" : "circle")
                            .imageScale(.large)
                            .foregroundColor(selectedBoxes.contains(box) ? .accentColor : Color(UIColor.separator))
                        VStack(alignment: .leading) {
                            Text(box.name ?? "?")
                            Text(box.location?.name ?? "?")
                                .font(.caption)
                                .opacity(0.5)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
                    .onTapGesture {
                        if selectedBoxes.contains(box) {
                            selectedBoxes.remove(box)
                        } else {
                            selectedBoxes.insert(box)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Generate QR codes")
        .toolbar {
            Button("Generate") {
                generate()
            }
            .disabled(futureCount == 0 && selectedBoxes.isEmpty)
        }
        .sheet(item: $generator.url) { url in
            ExportView(fileURL: url) {
                generator.delete()
            }
        }
    }

    private func generate() {
        let lastID = max(storage.lastBoxID, Int(selectedBoxes.map { $0.code }.max() ?? 0))

        let currentCodes = selectedBoxes.map {
            QRGenerator.Box(code: $0.qrCode, name: $0.name, location: $0.location?.name)
        }

        let futureCodes = Array((lastID + 1)...(lastID + futureCount)).map {
            QRGenerator.Box(code: "S-" + String(format: "%08d", $0), name: nil, location: nil)
        }

        let codes = currentCodes + futureCodes
        generator.generate(codes)
    }
}

struct QRSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QRSettingsView()
        }
    }
}
