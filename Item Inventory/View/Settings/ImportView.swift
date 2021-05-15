//
//  ImportView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 15/05/2021.
//

import UIKit
import SwiftUI

struct ImportView: UIViewControllerRepresentable {

    class Coordinator: NSObject, UIDocumentPickerDelegate {

        let didPickHandler: (URL) -> Void

        init(didPickHandler: @escaping (URL) -> Void) {
            self.didPickHandler = didPickHandler
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                didPickHandler(url)
            }
        }
    }

    let didPickHandler: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.zip])
        controller.delegate = context.coordinator

        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(didPickHandler: didPickHandler)
    }

}
