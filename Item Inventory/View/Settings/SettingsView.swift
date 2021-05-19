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

    @ObservedObject
    var manager: ImportExportManager

    @State private var isShowingDeleteAlert = false
    @State private var isShowingImportView = false

    @State private var errorMessage: String?

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
                    .listRowInsets(EdgeInsets(top: 8.0, leading: 16.0, bottom: 8.0, trailing: 16.0))

                }
                Section(header: Text("Import / Export")) {

                    // Export button
                    Button {
                        manager.exportData()
                    } label: {
                        if manager.isExporting {
                            HStack(alignment: .center, spacing: 12.0) {
                                ProgressView()
                                Text("Exporting...")
                                    .foregroundColor(.primary)
                                    .opacity(0.5)
                            }
                            .padding(.horizontal, 4.0)
                        } else {
                            Label("Export data", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(manager.isExporting)

                    // Export error
                    if let exportError = manager.exportError {
                        HStack(alignment: .center, spacing: 8.0) {
                            Image(systemName: "xmark.circle")
                                .imageScale(.large)
                                .foregroundColor(.red)
                                .opacity(0.5)
                            Text(exportError)
                        }
                        .listRowInsets(EdgeInsets(top: 8.0, leading: 20.0, bottom: 8.0, trailing: 20.0))
                    }

                    // Import button
                    Button {
                        isShowingImportView = true
                    } label: {
                        if manager.isImporting {
                            HStack(alignment: .center, spacing: 12.0) {
                                ProgressView()
                                Text("Importing...")
                                    .foregroundColor(.primary)
                                    .opacity(0.5)
                            }
                            .padding(.horizontal, 4.0)
                        } else {
                            Label("Import data", systemImage: "square.and.arrow.down")
                        }
                    }
                    .disabled(manager.isImporting)

                    // Import error
                    if let importError = manager.importError {
                        HStack(alignment: .center, spacing: 8.0) {
                            Image(systemName: "xmark.circle")
                                .imageScale(.large)
                                .foregroundColor(.red)
                                .opacity(0.5)
                            Text(importError)
                        }
                        .listRowInsets(EdgeInsets(top: 8.0, leading: 20.0, bottom: 8.0, trailing: 20.0))
                    }

                }
                Section(header: Text("QR codes"), footer: Text("Generate and print QR codes to put them on a box")) {
                    NavigationLink(destination: QRSettingsView()) {
                        Label("Generate QR codes", systemImage: "doc")
                    }
                }
                Section(header: Text("About"), footer: Text("Copyright © \(year) Przemysław Ambroży")) {
                    HStack(spacing: 16.0) {
                        Image("AppIconSVG")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 0.2237 * 64, style: .continuous))
                        VStack(alignment: .leading, spacing: 4.0) {
                            Text(appName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("version \(version) (\(build))")
                                .font(.footnote)
                                .opacity(0.5)
                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4.0)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $isShowingDeleteAlert) {
            Alert(title: Text("Are you sure?"),
                  message: Text("Do you want to delete all the data? This process cannot be undone"),
                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Delete"), action: {
                    storage.deleteAllData()
                  }))
        }
        .sheet(item: $manager.exportFileURL) { url in
            ExportView(fileURL: url, completion: manager.didExport)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $isShowingImportView) {
            ImportView { url in
                manager.importData(from: url)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onDisappear {
            // Clean up
            try? manager.prepareExport()
        }
    }

    private var appName: String {
        (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? "???"
    }

    private var year: String {
        String(max(Calendar.current.component(.year, from: Date()), 2021))
    }

    private var version: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "???"
    }

    private var build: String {
        "build " + ((Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "???")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(manager: ImportExportManager(.shared))
    }
}
