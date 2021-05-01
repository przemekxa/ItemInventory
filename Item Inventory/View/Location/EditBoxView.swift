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

    @Environment(\.presentationMode)
    private var presentationMode


    private var box: Box?


    // Box properties

    @State private var name: String = ""

    @State private var location: Location

    @State private var comment: String = ""

    @State private var code: Int = 0

    @State private var image: UIImage?

    @State private var imageUUID: String?

    // State

    @State private var isScanning = false

    @State private var pickingImage: UIImagePickerController.SourceType?

    @State private var errorMessage: String?

    /// Don't allow saving while image is being processed
    @State private var isProcessingImage = false

    @State private var isSaving = false

    /// Create a new box
    init(_ location: Location) {
        _location = State(initialValue: location)
        _code = State(initialValue: storage.lastBoxID + 1)
    }

    /// Edit existing box
    init(_ box: Box) {
        self.box = box
        _location = State(initialValue: box.location!)
        _name = State(initialValue: box.name ?? "")
        _comment = State(initialValue: box.comment ?? "")
        _code = State(initialValue: Int(box.code))
        if
            let imageUUID = box.imageUUID,
            let imageData = try? Data(contentsOf: storage.imageURL(for: imageUUID)),
            let image = UIImage(data: imageData) {

            self._imageUUID = State(initialValue: imageUUID)
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
                    VStack(alignment: .leading) {
                        Text("QR code")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text(formattedID)
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
                            .frame(maxHeight: 200.0)
                            .padding(.horizontal, -24.0)
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
                        // Delete new image
                        if
                            let newImageUUID = imageUUID,
                            let originalUUID = box?.imageUUID,
                            newImageUUID != originalUUID {
                            storage.deleteImage(with: newImageUUID)
                        }
                        presentationMode.wrappedValue.dismiss()
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
                        .disabled(name.isEmpty || isProcessingImage)
                    }
                }
            }
            .sheet(isPresented: $isScanning) {
                QRView(handler: handleScan(result:))
            }
            .sheet(item: $pickingImage) { method in
                ImagePicker(image: $image, sourceType: method)
            }
            .alert(item: $errorMessage) { message in
                Alert(title: Text("Error"),
                      message: Text(message),
                      dismissButton: .default(Text("OK")))
            }
            // Process image to PNG data
            .onChange(of: image) { newImage in
                if newImage != nil {
                    processImage()
                } else {
                    imageUUID = nil
                }
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
    private func handleScan(result: QRView.Result) {
        isScanning = false
        if case .success(let code) = result {
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

    /// Process image (change to JPG) on background thread
    private func processImage() {
        guard let image = image else { return }

        isProcessingImage = true
        DispatchQueue.global(qos: .userInitiated).async {

            // Conver and save new image
            let data = image.jpegData(compressionQuality: 0.7)!
            let uuid = storage.saveImage(data)

            // Delete old image (if not from existing Box)
            if let originalUUID = box?.imageUUID,
               let currentUUID = imageUUID,
               originalUUID != currentUUID {
                storage.deleteImage(with: currentUUID)
            }

            DispatchQueue.main.async {
                imageUUID = uuid
                isProcessingImage = false
            }
        }
    }

    /// Add a new box
    private func add() {
        isSaving = true
        storage.addBox(name: name,
                       location: location,
                       comment: comment,
                       code: code,
                       imageUUID: imageUUID)
        presentationMode.wrappedValue.dismiss()
    }

    /// Save edited box
    private func save() {
        isSaving = true
        storage.editBox(box: box!,
                        name: name,
                        location: location,
                        comment: comment,
                        code: code,
                        imageUUID: imageUUID)
        presentationMode.wrappedValue.dismiss()
    }


}

struct EditBoxView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditBoxView(Location())
        }
    }
}
