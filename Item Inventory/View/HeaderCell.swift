//
//  HeaderCell.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 05/05/2021.
//

import SwiftUI

struct HeaderCell<Content: View>: View {

    init(_ header: String, content: @escaping () -> Content) {
        self.header = header
        self.content = content
    }

    var header: String

    var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            Text(header)
                .font(.caption)
                .foregroundColor(Color(UIColor.secondaryLabel))
            content()
        }
        .padding(.vertical, 6.0)
    }
}

struct HeaderCell_Previews: PreviewProvider {
    static var previews: some View {
        HeaderCell("Example") {
            Text("Hello")
        }
    }
}
