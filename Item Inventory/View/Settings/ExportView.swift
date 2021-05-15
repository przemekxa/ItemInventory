//
//  ExportView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 15/05/2021.
//

import UIKit
import SwiftUI

extension URL: Identifiable {
    public var id: URL { self }
}

struct ExportView: UIViewControllerRepresentable {

    let fileURL: URL
    let completion: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {

        let controller = UIActivityViewController(activityItems: [fileURL],
                                                  applicationActivities: nil)
        controller.completionWithItemsHandler = { (_, _, _, _) in
            completion()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }

}
