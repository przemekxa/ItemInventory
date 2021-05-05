//
//  ItemCellView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI
import Kingfisher

struct ItemCellView: View {

    @Environment(\.storage)
    private var storage

    var item: Item

    var body: some View {
        HStack(spacing: 12.0) {

            if let imageIdentifier = item.imageIdentifiers.first {
                KFImage(storage.imageStore.imageURL(for: imageIdentifier))
                    .cancelOnDisappear(true)
                    .loadImmediately()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64, alignment: .center)
                    .cornerRadius(8.0)

            } else {
                Image(systemName: "square.slash")
                    .imageScale(.large)
                    .opacity(0.5)
                    .frame(width: 64, height: 64, alignment: .center)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8.0)
            }

            VStack(alignment: .leading) {
                Text(item.name ?? "?")
                Text(item.keywords ?? " ")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text(item.comment ?? " ")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
    }
}

struct ItemCellView_Previews: PreviewProvider {

    static var previews: some View {
        ItemCellView(item: Item())
            .previewLayout(.fixed(width: 320, height: 60))
    }
}
