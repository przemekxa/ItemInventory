//
//  EmptyableList.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import SwiftUI

struct EmptyableList<Items: Collection, Content: View>: View {

    private let isEmpty: Bool
    private let emptyImage: String
    private let emptyText: String
    private let content: () -> Content

    init(items: Items,
         emptyImage: String = "square.slash",
         emptyText: String,
         content: @escaping () -> Content) {
        self.isEmpty = items.isEmpty
        self.emptyImage = emptyImage
        self.emptyText = emptyText
        self.content = content
    }

    var body: some View {
        if isEmpty {
            List {
                VStack(alignment: .center, spacing: 12.0) {
                    Image(systemName: emptyImage)
                        .imageScale(.large)
                        .opacity(0.3)
                    Text(emptyText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16.0)
            }
        } else {
            List {
                content()
            }
        }
    }
}

struct EmptyableList_Previews: PreviewProvider {
    static var previews: some View {
        EmptyableList(items: [], emptyText: "Empty") {
            Text("Not empty")
        }
    }
}
