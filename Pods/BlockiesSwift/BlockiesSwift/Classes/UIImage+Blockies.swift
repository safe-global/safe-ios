//
//  UIImage+Blockies.swift
//  BlockiesSwift
//
//  Created by Dmitry Bespalov on 20.11.18.
//  Copyright © 2018 Dmitry Bespalov. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

private var BlockiesSeedHandle: UInt8 = 0
private var BlockiesSizeHandle: UInt8 = 0
private var BlockiesScaleHandle: UInt8 = 0

extension UIImageView {

    public var blockiesSeed: String? {
        get {
            return objc_getAssociatedObject(self, &BlockiesSeedHandle) as? String
        }
        set {
            objc_setAssociatedObject(self,
                                     &BlockiesSeedHandle,
                                     newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_COPY)
            redraw()
        }
    }

    public var blockiesSize: Int? {
        get {
            return objc_getAssociatedObject(self, &BlockiesSizeHandle) as? Int
        }
        set {
            objc_setAssociatedObject(self,
                                     &BlockiesSizeHandle,
                                     newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_COPY)
            redraw()
        }
    }

    public var blockiesScale: Int? {
        get {
            return objc_getAssociatedObject(self, &BlockiesScaleHandle) as? Int
        }
        set {
            objc_setAssociatedObject(self,
                                     &BlockiesScaleHandle,
                                     newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_COPY)
            redraw()
        }
    }

    private func redraw() {
        guard let seed = blockiesSeed else {
            image = nil
            return
        }
        let size = blockiesSize ?? 8
        let scale = blockiesScale ?? 3
        let pixelSize = Int(frame.height * UIScreen.main.scale / CGFloat(scale))
        image = Blockies(seed: seed, size: size, scale: pixelSize).createImage()
    }

}

#endif
