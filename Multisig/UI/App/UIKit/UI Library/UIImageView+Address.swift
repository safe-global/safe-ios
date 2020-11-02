//
//  IdenticonView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import BlockiesSwift
import Kingfisher

extension UIImageView {

    /// Sets the image to a blockies pattern generated from the `value`.
    /// - Parameter value: address to use. Must be hexadecimal and lowercased.
    func setAddress(_ value: String) {
        let provider = BlockiesImageProvider(seed: value)
        let processor = RoundCornerImageProcessor(cornerRadius: provider.width)
        kf.setImage(with: provider, options: [.processor(processor)])
    }
}

/// Generates a blockies image from a seed and provides for use in kingfisher.
/// This allows to use Kingfisher's caching and image processing features.
struct BlockiesImageProvider: ImageDataProvider {
    var seed: String
    var blockSize: UInt = 8
    var width: CGFloat = 250
    var height: CGFloat = 250
    var cacheKey: String { "\(seed)@\(blockSize)-\(width)x\(height)" }

    func data(handler: @escaping (Result<Data, Error>) -> Void) {
        let size = blockSize == 0 ? 8 : blockSize
        let blockies = Blockies(
            seed: seed,
            size: Int(size),
            scale: Int(min(width, height) / CGFloat(size))
        )
        if let image = blockies.createImage(), let data = image.pngData() {
            handler(.success(data))
        } else {
            handler(.failure("Failed to create blockies for \(seed)"))
        }
    }
}
