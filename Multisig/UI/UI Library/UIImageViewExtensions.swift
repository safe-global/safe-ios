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
    func setAddress(_ value: String, width: CGFloat = 250, height: CGFloat = 250) {
        let provider = BlockiesImageProvider(seed: value, width: width, height: height)
        let processor = RoundCornerImageProcessor(radius: .widthFraction(0.5))
        kf.setImage(with: provider, options: [.processor(processor)])
    }
}

extension UIImageView {
    /// Loads the image from URL or sets a placeholder image instead.
    /// The image will be cropped as a circle.
    ///
    /// - Parameters:
    ///   - url: url to load image from
    ///   - placeholder: placeholder image
    func setCircleShapeImage(url: URL?, placeholder: UIImage) {
        kf.setImage(with: url,
                    placeholder: placeholder,
                    options: [.processor(RoundCornerImageProcessor(radius: .widthFraction(0.5)))])
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
        if let image = image(), let data = image.pngData() {
            handler(.success(data))
        } else {
            handler(.failure("Failed to create blockies for \(seed)"))
        }
    }

    func image() -> UIImage? {
        let size = blockSize == 0 ? 8 : blockSize
        let blockies = Blockies(
            seed: seed,
            size: Int(size),
            scale: Int(min(width, height) / CGFloat(size))
        )
        return blockies.createImage()
    }

    // https://stackoverflow.com/questions/7705879/ios-create-a-uiimage-or-uiimageview-with-rounded-corners
    func roundImage() -> UIImage? {
        guard let image = image() else { return nil }

        let imageLayer = CALayer()
        imageLayer.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        imageLayer.contents = image.cgImage
        imageLayer.masksToBounds = true
        imageLayer.cornerRadius = image.size.width / 2
        UIGraphicsBeginImageContext(image.size)
        imageLayer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage
    }
}
