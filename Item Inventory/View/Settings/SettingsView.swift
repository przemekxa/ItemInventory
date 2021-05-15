//
//  SettingsView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 15/05/2021.
//

import SwiftUI

struct SettingsView: View {

    @Environment(\.storage)
    private var storage

    @State private var isShowingDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data"), footer: Text("This operation cannot be undone")) {
                    Button {
                        isShowingDeleteAlert = true
                    } label: {
                        Label("Delete all data", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
                Section(header: Text("Import / Export")) {
                    Button {

                    } label: {
                        Label("Export data", systemImage: "square.and.arrow.up")
                    }
                    Button {

                    } label: {
                        Label("Import data", systemImage: "square.and.arrow.down")
                    }
                }
                Section(header: Text("QR codes"), footer: Text("Generate and print QR codes to put them on a box")) {
                    NavigationLink(destination: Text("Destination")) {
                        Label("Generate QR codes", systemImage: "doc")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(title: Text("Are you sure?"),
                  message: Text("Do you want to delete all the data? This process cannot be undone"),
                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Delete"), action: {
                    storage.deleteAllData()
                  }))
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
