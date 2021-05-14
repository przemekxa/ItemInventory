//
//  EditBoxView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI

struct EditBoxView: View {

    @Environment(\.storage)
    private var storage

    @ObservedObject
    private var cache: ImageCache

    @Environment(\.presentationMode)
    private var presentationMode

    private var box: Box?


    // Box properties

    @State private var name: String = ""

    @State private var location: Location

    @State private var comment: String = ""

    @State private var code: Int = 0

    @State private var image: UIImage?

    // State

    @State private var isScanning = false

    @State private var pickingImage: UIImagePickerController.SourceType?

    @State private var errorMessage: String?

    @State private var isCancelling = false
    @State private var isSaving = false

    /// Create a new box
    init(_ storage: Storage, location: Location) {
        _location = State(initialValue: location)
        _code = State(initialValue: storage.lastBoxID + 1)
        _cache = ObservedObject(initialValue: storage.imageCache(initial: []))
    }

    /// Edit existing box
    init(_ storage: Storage, box: Box) {
        self.box = box
        _location = State(initialValue: box.location!)
        _name = State(initialValue: box.name ?? "")
        _comment = State(initialValue: box.comment ?? "")
        _code = State(initialValue: Int(box.code))
        _cache = ObservedObject(initialValue: storage.imageCache(initial: [box.imageUUID].compactMap { $0 }))
        if
            let imageUUID = box.imageUUID,
            let imageData = try? Data(contentsOf: storage.imageStore.imageURL(for: imageUUID)),
            let image = UIImage(data: imageData) {

            self._image = State(initialValue: image)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                Picker("Location", selection: $location) {
                    ForEach(storage.locations) { location in
                        Text(location.name ?? "?").tag(location)
                    }
                }
                TextField("Comment", text: $comment)

                HStack {
                    VStack(alignment: .leading, spacing: 4.0) {
                        Text("QR code")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text(formattedID)
                            .font(.system(.body, design: .monospaced))
                    }
                    Spacer()
                    Button {
                        isScanning = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .imageScale(.large)
                    }
                }
                .padding(.vertical, 2.0)

                Section(header: Text("Image")) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .listRowInsets(EdgeInsets())
                        Button {
                            withAnimation {
                                self.image = nil
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .foregroundColor(.red)
                        imageButton("Pick another")

                    } else {
                        imageButton("Select image")
                    }

                }
            }
            .navigationTitle(box == nil ? "Add box" : "Edit box")
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
                        Button(box == nil ? "Add" : "Save") {
                            if box == nil {
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
                QRBarcodeView(objectTypes: [.qr], handler: handleScan(result:))
            }
            .sheet(item: $pickingImage) { method in
                ImagePicker(image: $image, sourceType: method)
            }
            .alert(item: $errorMessage) { message in
                Alert(title: Text("Error"),
                      message: Text(message),
                      dismissButton: .default(Text("OK")))
            }
            // Process an image change
            .onChange(of: image) { newImage in

                // There is a new image
                if let newImage = newImage {
                    if let oldImage = cache.images.first {
                        cache.replace(oldImage, with: newImage)
                    } else {
                        cache.add(newImage)
                    }

                // The image was deleted
                } else {
                    if let oldImage = cache.images.first {
                        cache.delete(oldImage)
                    }
                }
            }
        }
        .onDisappear {
            if !isCancelling && !isSaving {
                cancel()
            }
        }
    }

    /// ID in appropriate format
    private var formattedID: String {
        "S-" + String(format: "%08d", code)
    }

    /// Image picker button
    private func imageButton(_ title: String) -> some View {
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
            Label(title, systemImage: "photo")
        }
    }

    /// Handle the QR scan result
    private func handleScan(result: QRBarcodeView.Result) {
        isScanning = false
        if case .success(let code, _) = result {
            let regex = try! NSRegularExpression(pattern: #"S-\d{8}"#)
            if regex.firstMatch(in: code,
                                options: [],
                                range: NSRange(location: 0, length: code.utf16.count)) != nil {

                let startIndex = code.index(code.startIndex, offsetBy: 2)
                let endIndex = code.index(code.startIndex, offsetBy: 9)
                let id = Int(code[startIndex...endIndex])!
                if storage.hasBox(with: id) {
                    errorMessage = "This code is already being used"
                } else {
                    self.code = id
                }
            } else {
                errorMessage = "Wrong code format"
            }
        }

    }

    /// Cancel adding or editing a box
    private func cancel() {
        isCancelling = true
        cache.cancel()
        presentationMode.wrappedValue.dismiss()
    }

    /// Add a new box
    private func add() {
        isSaving = true
        cache.save()
        storage.addBox(name: name,
                       location: location,
                       comment: comment,
                       code: code,
                       imageUUID: cache.images.first)
        presentationMode.wrappedValue.dismiss()
    }

    /// Save edited box
    private func save() {
        isSaving = true
        cache.save()
        storage.editBox(box: box!,
                        name: name,
                        location: location,
                        comment: comment,
                        code: code,
                        imageUUID: cache.images.first)
        presentationMode.wrappedValue.dismiss()
    }


}

struct EditBoxView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditBoxView(Storage.shared, location: Location())
        }
    }
}
