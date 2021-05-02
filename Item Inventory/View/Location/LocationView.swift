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

    @State
    private var editBoxSheet: Box?

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
                    destination: Text("Destination"),
                    label: { cell(for: box) })
                    .contextMenu {
                        Button {
                            editBoxSheet = box
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button {
                            storage.delete(box)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                indexSet
                    .map { boxes[$0] }
                    .forEach { storage.delete($0) }
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
                Image(systemName: "square.slash")
                    .imageScale(.large)
                    .opacity(0.5)
                    .frame(width: 64, height: 64, alignment: .center)
                    .background(Color(UIColor.secondarySystemBackground))
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

}

struct LocationView_Previews: PreviewProvider {

    static var previews: some View {
        LocationView(Location())
    }
}
