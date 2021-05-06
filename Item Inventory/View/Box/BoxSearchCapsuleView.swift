//
//  BoxSearchCapsuleView.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 06/05/2021.
//

import SwiftUI

struct BoxSearchCapsuleView: View {

    enum Mode {
        case error
        case boxNotFound
        case wrongBox
        case correctBox

        var image: String {
            switch self {
            case .error:
                return "exclamationmark.circle.fill"
            case .boxNotFound:
                return "questionmark.circle.fill"
            case .wrongBox:
                return "multiply.circle.fill"
            case .correctBox:
                return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .error, .wrongBox, .boxNotFound:
                return .red
            case .correctBox:
                return .green
            }
        }
    }

    var mode: Mode

    var name: String?

    var qrCode: String?

    var retry: () -> Void

    var body: some View {
        HStack(spacing: 12.0) {
            Image(systemName: mode.image)
                .resizable()
                .frame(width: 32, height: 32, alignment: .center)
                .foregroundColor(mode.color)
            VStack(alignment: .leading, spacing: 0.0) {
                Text(statusText)
                    .font(.footnote)
                    .lineLimit(1)
                if let name = name {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                if let code = qrCode {
                    HStack(spacing: 2.0) {
                        Text("QR Code: ")
                            .font(.caption)
                        Text(code)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding(.top, 2.0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                retry()
            } label: {
                VStack(spacing: 4.0) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24, alignment: .center)
                        .foregroundColor(.blue)
                    Text("Retry")
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8.0)
        .padding(.leading, 16.0)
        .padding(.trailing, 24.0)
        .background(
            RoundedRectangle(cornerRadius: 32.0, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 0)
        )
        .padding(16.0)
    }

    private var statusText: String {
        switch mode {
        case .error:
            return "An error occured"
        case .boxNotFound:
            return "Box not found"
        case .wrongBox:
            return "Wrong box"
        case .correctBox:
            return "Correct box"
        }
    }
}

struct BoxSearchCapsuleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BoxSearchCapsuleView(mode: .correctBox, name: "Name", qrCode: "S-123") {}
                .previewLayout(.fixed(width: 380.0, height: 120.0))
            BoxSearchCapsuleView(mode: .wrongBox, name: "Name", qrCode: "S-123") {}
                .previewLayout(.fixed(width: 380.0, height: 120.0))
            BoxSearchCapsuleView(mode: .boxNotFound, name: nil, qrCode: "S-123") {}
                .previewLayout(.fixed(width: 380.0, height: 120.0))
            BoxSearchCapsuleView(mode: .error, name: nil, qrCode: nil) {}
                .previewLayout(.fixed(width: 380.0, height: 120.0))
        }
    }
}
