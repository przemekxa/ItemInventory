//
//  BoxHeaderView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 04/05/2021.
//

import SwiftUI
import Kingfisher

struct BoxHeaderView: View {

    @Environment(\.storage)
    private var storage

    @ObservedObject var box: Box

    @Binding var isEditing: Bool

    @Binding var showDeleteSheet: Bool

    @Binding var showFindBoxSheet: Bool

    @State private var isExpanded = false

    var body: some View {
        Group {
            if let imageURL = imageURL {
                KFImage(imageURL)
                    .resizable()
                    .loadImmediately()
                    .scaledToFill()
                    .frame(maxHeight: isExpanded ? .infinity : 200.0 as CGFloat)
                    .listRowInsets(EdgeInsets())
                    .animation(nil)
            }

            VStack(alignment: .leading, spacing: 4.0) {
                Text("Comment")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                if let comment = box.comment, !comment.isEmpty {
                    Text(comment)
                        .lineLimit(isExpanded ? nil : 1)
                } else {
                    Text("No comment")
                        .opacity(0.5)
                }
            }
            .animation(nil)
            .padding(.vertical, 6.0)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4.0) {
                    Text("QR Code")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Text(box.qrCode)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(isExpanded ? nil : 1)
                }
                .padding(.vertical, 6.0)
                Button {
                    showFindBoxSheet = true
                } label: {
                    Label("Find box by QR code", systemImage: "qrcode")
                }
                Button {
                    isEditing = true
                } label: {
                    Label("Edit box", systemImage: "pencil")
                }
                Button {
                    showDeleteSheet = true
                } label: {
                    Label("Delete box", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label(isExpanded ? "Show less" : "Show more", systemImage: "ellipsis")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(nil)
                    Image(systemName: "arrow.down")
                        .rotation3DEffect(
                            .degrees(isExpanded ? 180 : 0),
                            axis: (x: 1.0, y: 0.0, z: 0.0)
                        )
                }
            }
        }
    }

    private var imageURL: URL? {
        if let imageIdentifier = box.imageUUID {
            return storage.imageStore.imageURL(for: imageIdentifier)
        }
        return nil
    }
}

struct BoxHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        BoxHeaderView(box: Box(),
                      isEditing: .constant(false),
                      showDeleteSheet: .constant(false),
                      showFindBoxSheet: .constant(false))
    }
}
