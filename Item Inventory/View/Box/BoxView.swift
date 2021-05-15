//
//  BoxView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 03/05/2021.
//

import SwiftUI
import Kingfisher

struct BoxView: View {

    @Environment(\.storage)
    private var storage

    @Environment(\.presentationMode)
    private var presentationMode

    @FetchRequest
    private var items: FetchedResults<Item>

    @ObservedObject
    private var box: Box

    @State private var addItemSheet = false

    @State private var editItemSheet: Item?

    @State private var isEditing = false

    @State private var showDeleteSheet = false

    @State private var showFindBoxSheet = false

    init(_ box: Box) {
        self._box = ObservedObject(initialValue: box)

        let sortDescriptor = NSSortDescriptor(keyPath: \Item.name, ascending: true)
        let predicate = NSPredicate(format: "box == %@", box)

        _items = FetchRequest(entity: Item.entity(),
                              sortDescriptors: [sortDescriptor],
                              predicate: predicate)
    }

    var body: some View {
        List {
            Section(header: Text("Box")) {
                BoxHeaderView(box: box,
                              isEditing: $isEditing,
                              showDeleteSheet: $showDeleteSheet,
                              showFindBoxSheet: $showFindBoxSheet)
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
        .navigationTitle(box.name ?? "?")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit box", systemImage: "pencil")
                    }
                    Button {
                        showDeleteSheet = true
                    } label: {
                        Label("Delete box", systemImage: "trash")
                    }
                    Button {
                        showFindBoxSheet = true
                    } label: {
                        Label("Find box by QR code", systemImage: "qrcode")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                }
            }
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
            ItemEditView(storage, box: box)
        }
        .sheet(item: $editItemSheet) { item in
            ItemEditView(storage, item: item)
        }
        .sheet(isPresented: $isEditing) {
            EditBoxView(storage, box: box)
        }
        .actionSheet(isPresented: $showDeleteSheet) {
            deleteActionSheet()
        }
        .fullScreenCover(isPresented: $showFindBoxSheet) {
            BoxSearchView(box: box)
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
                    .setProcessor(DownsamplingImageProcessor.scaled64)
                    .cancelOnDisappear(true)
                    .loadImmediately()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64, alignment: .center)
                    .cornerRadius(8.0)

            } else {
                Image("slash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64, alignment: .center)
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

    func deleteActionSheet() -> ActionSheet {

        var buttons = [ActionSheet.Button.cancel()]
        var message: Text?

        if items.isEmpty {
            buttons.append(.destructive(Text("Delete box")) {
                storage.delete(box, keepItems: false)
                presentationMode.wrappedValue.dismiss()
            })
        } else {
            message = Text("If you choose \"Delete box, keep items\", your items will be moved to general space.")
            buttons.append(.destructive(Text("Delete box and items inside")) {
                storage.delete(box, keepItems: false)
                presentationMode.wrappedValue.dismiss()
            })
            buttons.append(.destructive(Text("Delete box, keep items")) {
                storage.delete(box, keepItems: true)
                presentationMode.wrappedValue.dismiss()
            })
        }

        return ActionSheet(title: Text("Do you want to delete this box?"),
                           message: message,
                           buttons: buttons)
    }

    
}

struct BoxView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BoxView(Box())
        }
    }
}
