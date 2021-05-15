//
//  LocationsView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI
import CoreData

struct LocationsView: View {

    @Environment(\.storage)
    private var storage

    @FetchRequest(
        entity: Location.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Location.name, ascending: true)])
    private var locations: FetchedResults<Location>

    @State private var addLocationSheet = false

    @State private var editLocationSheet: Location?

    @State private var cannotDeleteLocationNotEmpty: Location?

    var body: some View {
        NavigationView {
            List {
                Section(footer: Text("The general space contains all items that are not in any box.")) {
                    NavigationLink("General space", destination: GeneralSpaceView())
                }
                Section(header: Text("Locations")) {
                    if locations.isEmpty {
                        VStack(alignment: .center, spacing: 12.0) {
                            Image(systemName: "square.slash")
                                .imageScale(.large)
                                .opacity(0.3)
                            Text("No locations")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16.0)
                    } else {
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
                                    .disabled(location.hasBoxes)

                                }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                if locations[index].hasBoxes {
                                    cannotDeleteLocationNotEmpty = locations[index]
                                } else {
                                    storage.delete(locations[index])
                                }
                            }
                        }
                    }
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
        .alert(item: $cannotDeleteLocationNotEmpty) { location in
            Alert(title: Text("Cannot delete"),
                  message: Text("Cannot delete location \"\(location.name ?? "")\": location is not empty"),
                  dismissButton: .default(Text("OK")))
        }
    }

}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView()
    }
}
