//
//  ItemEditView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 04/05/2021.
//

import SwiftUI
import Kingfisher

struct ItemEditView: View {

    @Environment(\.storage)
    private var storage

    @ObservedObject
    private var cache: ImageCache

    @Environment(\.presentationMode)
    private var presentationMode

    private var item: Item?

    // Item properties

    @State private var name: String = ""

    @State private var box: Box?

    @State private var comment: String = ""

    @State private var keywords: String = ""

    @State private var barcode: String?

    @State private var scannedImage: UIImage?

    // State

    @State private var editMode = EditMode.inactive

    @State private var isScanning = false

    @State private var pickingImage: UIImagePickerController.SourceType?

    @State private var isCancelling = false
    @State private var isSaving = false

    /// Create a new item
    init(_ storage: Storage, box: Box?) {
        _box = State(initialValue: box)
        _cache = ObservedObject(initialValue: storage.imageCache(initial: []))
    }

    /// Edit an existing item
    init(_ storage: Storage, item: Item) {
        self.item = item
        _name = State(initialValue: item.name ?? "")
        _box = State(initialValue: item.box)
        _comment = State(initialValue: item.comment ?? "")
        _keywords = State(initialValue: item.keywords ?? "")
        _barcode = State(initialValue: item.barcode)
        _cache = ObservedObject(initialValue: storage.imageCache(initial: item.imageIdentifiers))
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    Picker("Box", selection: $box) {
                        Text("General space").tag(nil as Box?)
                        ForEach(allBoxes(), id: \.0) { (box, name) in
                            Text(name).tag(box as Box?)
                        }
                    }
                    .disabled(editMode == .active)
                    TextField("Comment", text: $comment)
                    TextField("Keyword 1, keyword 2, ...", text: $keywords)
                    HStack {
                        VStack(alignment: .leading, spacing: 4.0) {
                            Text("Barcode (EAN/UPC)")
                                .font(.caption)
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            if let barcode = barcode {
                                Text(barcode)
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                Text("None")
                                    .opacity(0.5)
                            }
                        }
                        Spacer()
                        if barcode != nil {
                            Button {
                                barcode = nil
                            } label: {
                                Image(systemName: "trash")
                                    .imageScale(.large)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.red)
                            .padding(.leading, 8.0)
                        }
                        Button {
                            isScanning = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .imageScale(.large)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.leading, 8.0)
                    }
                    .padding(.vertical, 2.0)
                }

                Section(header:
                            HStack {
                                Text("Images")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(editMode == .active ? "Done" : "Rearrange") {
                                    withAnimation {
                                        editMode = editMode == .active ? .inactive : .active
                                    }
                                }
                                .animation(nil)
                            }
                ) {
                    ForEach(Array(cache.images)) { imageIdentifier in
                        HStack {
                            Spacer()
                            KFImage(storage.imageStore.imageURL(for: imageIdentifier))
                                .resizable()
                                .loadImmediately()
                                .scaledToFit()
                                .frame(maxHeight: 128, alignment: .center)
                                .padding(.vertical, 2.0)
                            Spacer()
                        }
                        .listRowBackground(
                            GeometryReader { geo in
                                KFImage(storage.imageStore.imageURL(for: imageIdentifier))
                                    .resizable()
                                    .loadImmediately()
                                    .scaledToFill()
                                    .blur(radius: 8.0)
                                    .frame(height: geo.size.height, alignment: .center)
                                    .clipped()
                            }
                        )
                        .listRowInsets(EdgeInsets())
                    }
                    .onDelete { indexSet in
                        for identifier in indexSet.map({ cache.images[$0] }) {
                            cache.delete(identifier)
                        }
                    }
                    .onMove { indices, newOffset in
                        cache.move(from: indices, to: newOffset)
                    }
                    if editMode != .active {
                        imageButton()
                    }
                }

            }
            .environment(\.editMode, $editMode)
            .navigationTitle(item == nil ? "Add an item" : "Edit an item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancel()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(item == nil ? "Add" : "Save") {
                            if item == nil {
                                add()
                            } else {
                                save()
                            }
                        }
                        .disabled(name.isEmpty || cache.inProgress > 0)
                    }
                }
            }
            .sheet(isPresented: $isScanning) {
                QRBarcodeView(objectTypes: [.ean8, .ean13, .upc], handler: handleScan(result:))
            }
            .sheet(item: $pickingImage) { method in
                ImagePicker(image: $scannedImage, sourceType: method)
            }
            // Process an image change
            .onChange(of: scannedImage) { newImage in
                // There is a new image
                if let newImage = newImage {
                    cache.add(newImage)
                    scannedImage = nil
                }
            }
        }
    }

    /// Return all boxes with their paths ("*Location name → Box name*")
    private func allBoxes() -> [(Box, String)] {
        storage.locations
            .compactMap { location -> [(Location, Box)]? in
                if let boxes = location.boxes?.allObjects as? [Box], !boxes.isEmpty {
                    return boxes.map { (location, $0) }
                } else {
                    return nil
                }
            }
            .flatMap { $0 }
            .map { (location, box) -> (Box, String) in
                let name = (location.name ?? "?") + " → " + (box.name ?? "?")
                return (box, name)
            }
    }

    /// Image picker button
    private func imageButton() -> some View {
        Menu {
            Button {
                pickingImage = .camera
            } label: {
                Label("Camera", systemImage: "camera")
            }
            Button {
                pickingImage = .photoLibrary
            } label: {
                Label("Photo library", systemImage: "photo")
            }
        } label: {
            Label("Add an image", systemImage: "plus.circle.fill")
        }
    }

    /// Handle the barcode scan result
    private func handleScan(result: QRBarcodeView.Result) {
        isScanning = false
        if case .success(let code, _) = result {
            barcode = code
        }

    }

    /// Cancel adding or editing an item
    private func cancel() {
        isCancelling = true
        cache.cancel()
        presentationMode.wrappedValue.dismiss()
    }

    /// Add a new item
    private func add() {
        isSaving = true
        cache.save()
        storage.addItem(name: name,
                        box: box,
                        keywords: keywords,
                        comment: comment,
                        barcode: barcode,
                        imageIdentifiers: Array(cache.images))
        presentationMode.wrappedValue.dismiss()
    }

    /// Save edited item
    private func save() {
        isSaving = true
        cache.save()
        storage.editItem(item!,
                         name: name,
                         box: box,
                         keywords: keywords,
                         comment: comment,
                         barcode: barcode,
                         imageIdentifiers: Array(cache.images))
        presentationMode.wrappedValue.dismiss()
    }
}

struct ItemEditView_Previews: PreviewProvider {
    static var previews: some View {
        ItemEditView(Storage.shared, box: Box())
    }
}
