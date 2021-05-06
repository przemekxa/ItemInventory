//
//  GeneralSpaceView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI
import Kingfisher

struct GeneralSpaceView: View {

    @Environment(\.storage)
    private var storage

    @Environment(\.presentationMode)
    private var presentationMode

    @FetchRequest(entity: Item.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Item.name, ascending: true)],
                  predicate: NSPredicate(format: "box == nil"))
    private var items: FetchedResults<Item>

    @State private var addItemSheet = false

    @State private var editItemSheet: Item?

    var body: some View {
        List {
            Section(header: Text("About")) {
                Text("This space contains all items that are not in any box.")
            }
            Section(header: Text("Items"), footer: Text("Items: \(items.count)")) {
                if items.isEmpty {
                    VStack(alignment: .center, spacing: 12.0) {
                        Image(systemName: "square.slash")
                            .imageScale(.large)
                            .opacity(0.3)
                        Text("No items")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16.0)
                } else {
                    ForEach(items) { item in
                        NavigationLink(
                            destination: ItemView(item),
                            label: {
                                cell(for: item)
                            })
                            .contextMenu {
                                contextMenu(for: item)
                            }
                    }
                    .onDelete { indexSet in
                        let itemsToDelete = indexSet.map { items[$0] }
                        for item in itemsToDelete {
                            storage.delete(item)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("General space")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            // SwiftUI back button disappearing workaround
            ToolbarItem(placement: .navigationBarLeading) { HStack {} }
        }
        .sheet(isPresented: $addItemSheet) {
            ItemEditView(storage, box: nil)
        }
        .sheet(item: $editItemSheet) { item in
            ItemEditView(storage, item: item)
        }
    }

    private func contextMenu(for item: Item) -> some View {
        Group {
            Button {
                editItemSheet = item
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button {
                storage.delete(item)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func cell(for item: Item) -> some View {
        HStack(spacing: 12.0) {

            if let imageIdentifier = item.imageIdentifiers.first {
                KFImage(storage.imageStore.imageURL(for: imageIdentifier))
                    .cancelOnDisappear(true)
                    .loadImmediately()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64, alignment: .center)
                    .cornerRadius(8.0)

            } else {
                Image(systemName: "square.slash")
                    .imageScale(.large)
                    .opacity(0.5)
                    .frame(width: 64, height: 64, alignment: .center)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8.0)
            }

            VStack(alignment: .leading) {
                Text(item.name ?? "?")
                Text(item.keywords ?? " ")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(item.comment ?? " ")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
    }

}

struct GeneralSpaceView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSpaceView()
    }
}
