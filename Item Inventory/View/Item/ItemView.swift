//
//  ItemView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI
import Kingfisher

struct ItemView: View {

    @Environment(\.storage)
    private var storage

    @Environment(\.presentationMode)
    private var presentationMode


    @ObservedObject
    private var item: Item

    @State private var isEditing = false

    init(_ item: Item) {
        _item = ObservedObject(initialValue: item)
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                HeaderCell("Name") { Text(item.name ?? "?") }
                HeaderCell("Location") { Text(item.box?.location?.name ?? "?") }
                HeaderCell("Box") { Text(item.box?.name ?? "?") }
                HeaderCell("Comment") { Text(item.comment ?? "") }
                HeaderCell("Keywords") { Text(item.keywords ?? "") }
                if let barcode = item.barcode {
                    HeaderCell("Barcode") {
                        Text(barcode)
                            .font(.system(.body, design: .monospaced))
                    }
                }

            }

            if !item.imageIdentifiers.isEmpty {
                Section(header: Text("Images")) {
                    ForEach(item.imageIdentifiers) { identifier in
                        KFImage(storage.imageStore.imageURL(for: identifier))
                            .resizable()
                            .loadImmediately()
                            .scaledToFill()
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
        }
        .navigationTitle(item.name ?? "?")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isEditing = true
                } label: { Image(systemName: "pencil") }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    storage.delete(item)
                    presentationMode.wrappedValue.dismiss()
                } label: { Image(systemName: "trash") }
            }
            // SwiftUI back button disappearing workaround
            ToolbarItem(placement: .navigationBarLeading) { HStack {} }
        }
        .sheet(isPresented: $isEditing) {
            ItemEditView(storage, item: item)
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct ItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ItemView(Item())
        }
    }
}
