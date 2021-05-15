//
//  Kingfisher.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 15/05/2021.
//

import CoreGraphics
import UIKit
import Kingfisher

extension DownsamplingImageProcessor {
    static var scaled64: Self {
        let size = 64.0 * UIScreen.main.scale
        return DownsamplingImageProcessor(size: CGSize(width: size, height: size))
    }
}
