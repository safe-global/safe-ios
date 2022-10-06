//
//  QRCodeView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class QRCodeView: UINibView {
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!

    var showsBorder: Bool = true

    var imageSizeInPoints: CGFloat = 300

    var value: String = "" {
        didSet {
            // QR code generation takes some seconds, so we do it in background to keep the UI responsive.
            self.imageView.image = nil
            self.spinner.startAnimating()

            let value = self.value
            let imageSize = self.imageSizeInPoints
            DispatchQueue.global().async { [weak self] in
                let image = UIImage.generateQRCode(value: value, size: .init(width: imageSize, height: imageSize))

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.spinner.stopAnimating()
                    self.imageView.image = image
                }
            }
        }
    }

    override func commonInit() {
        super.commonInit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if showsBorder {
            layer.borderWidth = 2
            layer.borderColor = UIColor.backgroundSecondary.cgColor
            layer.cornerRadius = 10
        } else {
            layer.borderWidth = 0
        }
    }

}
