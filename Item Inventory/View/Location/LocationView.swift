//
//  LocationView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI
import CoreData
import Kingfisher

struct LocationView: View {

    @Environment(\.storage)
    private var storage

    @FetchRequest
    private var boxes: FetchedResults<Box>

    @ObservedObject
    private var location: Location


    @State
    private var addBoxSheet = false

    @State private var editBoxSheet: Box?
    @State private var deleteBoxSheet: Box?

    init(_ location: Location) {
        self._location = ObservedObject(initialValue: location)

        let sortDescriptor = NSSortDescriptor(keyPath: \Box.code, ascending: true)
        let predicate = NSPredicate(format: "location == %@", location)

        _boxes = FetchRequest(entity: Box.entity(),
                              sortDescriptors: [sortDescriptor],
                              predicate: predicate)
    }

    var body: some View {
        EmptyableList(items: boxes, emptyText: "No boxes") {
            ForEach(boxes, id: \.self) { box in
                NavigationLink(
                    destination: BoxView(box),
                    label: { cell(for: box) })
                    .contextMenu {
                        Button {
                            editBoxSheet = box
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            deleteBoxSheet = box
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    let items = boxes[index].items?.allObjects as? [Item] ?? []
                    if items.isEmpty {
                        storage.delete(boxes[index], keepItems: false)
                    } else {
                        deleteBoxSheet = boxes[index]
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(location.name ?? "?")
        .toolbar {
            Button {
                addBoxSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $addBoxSheet) {
            EditBoxView(storage, location: location)
        }
        .sheet(item: $editBoxSheet) { box in
            EditBoxView(storage, box: box)
        }
        .actionSheet(item: $deleteBoxSheet, content: deleteBoxActionSheet(_:))
    }

    /// Cell view for a box
    func cell(for box: Box) -> some View {
        HStack(spacing: 12.0) {

            if let imageUUID = box.imageUUID {
                KFImage(storage.imageStore.imageURL(for: imageUUID))
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
                Text(box.name ?? "?")
                Text("Items: \(box.items?.count ?? -1)")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(box.comment ?? " ")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
    }

    private func deleteBoxActionSheet(_ box: Box) -> ActionSheet {

        let items: [Item] = (box.items?.allObjects as? [Item]) ?? []

        var buttons = [ActionSheet.Button.cancel()]
        var message: Text?

        if items.isEmpty {
            buttons.append(.destructive(Text("Delete box")) {
                storage.delete(box, keepItems: false)
            })
        } else {
            message = Text("If you choose \"Delete box, keep items\", your items will be moved to general space.")
            buttons.append(.destructive(Text("Delete box and items inside")) {
                storage.delete(box, keepItems: false)
            })
            buttons.append(.destructive(Text("Delete box, keep items")) {
                storage.delete(box, keepItems: true)
            })
        }

        return ActionSheet(title: Text("Do you want to delete this box?"),
                           message: message,
                           buttons: buttons)
    }

}

struct LocationView_Previews: PreviewProvider {

    static var previews: some View {
        LocationView(Location())
    }
}
