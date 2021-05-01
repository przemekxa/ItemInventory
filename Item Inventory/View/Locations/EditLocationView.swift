//
//  AddLocationView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI

struct EditLocationView: View {

    @Environment(\.presentationMode)
    private var presentationMode

    @Environment(\.storage)
    private var storage

    @State
    private var name: String = ""

    private var location: Location?


    /// Add new Location
    init() { }

    /// Edit exisiting location
    /// - Parameter location: Location to edit
    init(_ location: Location) {
        self.location = location
        self._name = State(initialValue: location.name ?? "")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Name of the location")) {
                    TextField("Name", text: $name)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(location == nil ? "Add location" : "Edit location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(location == nil ? "Add" : "Save") {
                        // Edit location
                        if let location = location {
                            storage.context.performAndWait {
                                location.name = name
                                storage.save()
                            }
                        }
                        // Add location
                        else {
                            storage.addLocation(named: name)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

}

struct AddLocationView_Previews: PreviewProvider {
    static var previews: some View {
        EditLocationView()
    }
}
