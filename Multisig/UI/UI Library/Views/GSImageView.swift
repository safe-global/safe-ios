//
//  GSImageView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class GSImageView: UIImageView {
    var imageData: ImageData? {
        didSet {
            if let data = imageData {
                data.apply(to: self)
            } else {
                image = nil
            }
        }
    }
}

protocol ImageData {
    var hasCircleShape: Bool { get set }
    func apply(to imageView: UIImageView)
}

struct RemoteImageData: ImageData {
    var url: URL
    var placeholder: UIImage?
    var error: UIImage?
    var hasCircleShape: Bool
    var completion: () -> Void

    func apply(to imageView: UIImageView) {
        let options: KingfisherOptionsInfo = [.processor(RoundCornerImageProcessor(radius: .widthFraction(0.5)))]
        imageView.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: hasCircleShape ? options : nil) { [weak imageView] result in

            guard let imageView = imageView else { return }

            switch result {
            case .success:
                break
            case .failure:
                if let error = self.error {
                    imageView.image = self.hasCircleShape ? error.circleShape() : error
                }
            }

            self.completion()
        }
    }
}

struct LocalImageData: ImageData {
    var image: UIImage?
    var hasCircleShape: Bool = false

    func apply(to imageView: UIImageView) {
        imageView.image = hasCircleShape ? image?.circleShape() : image
    }
}
