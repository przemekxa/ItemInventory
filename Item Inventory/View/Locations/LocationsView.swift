//
//  LocationsView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI

struct LocationsView: View {

    @Environment(\.storage)
    private var storage

    @FetchRequest(
        entity: Location.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)])
    private var locations: FetchedResults<Location>

    @State
    private var addLocationSheet = false

    @State
    private var editLocationSheet: Location?

    var body: some View {
        NavigationView {
            EmptyableList(items: locations, emptyText: "No locations") {
                ForEach(locations, id: \.self) { location in
                    NavigationLink(location.name ?? "?",
                                   destination: LocationView(location))
                        .contextMenu {
                            Button {
                                editLocationSheet = location
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                storage.delete(location)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete { indexSet in
                    indexSet
                        .map { locations[$0] }
                        .forEach { storage.delete($0) }
                }
            }
            .navigationTitle("Locations")
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                Button {
                    addLocationSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $addLocationSheet) {
            EditLocationView()
        }
        .sheet(item: $editLocationSheet) { location in
            EditLocationView(location)
        }
    }

}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView()
    }
}
