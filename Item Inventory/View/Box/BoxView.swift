//
//  BoxView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 03/05/2021.
//

import SwiftUI
import Kingfisher

struct BoxView: View {

    @Environment(\.storage)
    private var storage

    @FetchRequest
    private var items: FetchedResults<Item>

    @ObservedObject
    private var box: Box

    init(_ box: Box) {
        self._box = ObservedObject(initialValue: box)

        let sortDescriptor = NSSortDescriptor(keyPath: \Item.name, ascending: true)
        let predicate = NSPredicate(format: "box == %@", box)

        _items = FetchRequest(entity: Item.entity(),
                              sortDescriptors: [sortDescriptor],
                              predicate: predicate)
    }

    var body: some View {
        List {
            Section(header: Text("Box")) {
                BoxHeaderView(box: box)
            }
            Section(header: Text("Items"), footer: Text("Items: 0")) {
                Text("OK")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(box.name ?? "?")
    }

    
}

struct BoxView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BoxView(Box())
        }
    }
}
