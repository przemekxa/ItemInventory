//
//  ItemView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI
import Kingfisher

struct ItemView: View {

    @Environment(\.managedObjectContext)
    private var managedObjectContext

    @Environment(\.storage)
    private var storage

    @Environment(\.presentationMode)
    private var presentationMode

    @ObservedObject
    private var item: Item

    @State private var showDeleteAlert = false

    @State private var isEditing = false

    let allowsOpeningBoxAndLocation: Bool

    init(_ item: Item, allowsOpeningBoxAndLocation: Bool = false) {
        _item = ObservedObject(initialValue: item)
        self.allowsOpeningBoxAndLocation = allowsOpeningBoxAndLocation
    }

    var body: some View {
        List {
            Section(header: Text("Details")) {
                HeaderCell(Text("Name")) { Text(item.name ?? "?") }
                HeaderCell(Text("Location")) {
                    if allowsOpeningBoxAndLocation && item.box == nil {
                        NavigationLink("General space", destination:
                                        GeneralSpaceView()
                                            .environment(\.managedObjectContext, managedObjectContext)
                                            .environment(\.storage, storage)
                        )
                    } else {
                        Text(item.box?.location?.name ?? "General space")
                    }
                }
                HeaderCell(Text("Box")) {
                    if allowsOpeningBoxAndLocation, let box = item.box {
                        NavigationLink(box.name ?? "-", destination:
                                        BoxView(box)
                                            .environment(\.managedObjectContext, managedObjectContext)
                                            .environment(\.storage, storage)
                        )
                    } else {
                        Text(item.box?.name ?? "-")
                    }
                }
                HeaderCell(Text("Comment")) { Text(item.comment ?? "-") }
                HeaderCell(Text("Keywords")) { Text(item.keywords ?? "-") }
                if let barcode = item.barcode {
                    HeaderCell(Text("Barcode")) {
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
                    showDeleteAlert = true
                } label: { Image(systemName: "trash") }
            }
            // SwiftUI back button disappearing workaround
            ToolbarItem(placement: .navigationBarLeading) { HStack {} }
        }
        .sheet(isPresented: $isEditing) {
            ItemEditView(storage, item: item)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text("Are you sure you want to delete this item?"),
                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Delete")) {
                    storage.delete(item)
                    presentationMode.wrappedValue.dismiss()
                  }
            )
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
