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
    @IBOutlet private weak var imageView: UIImageView!

    var value: String = "" {
        didSet {
            // QR code generation takes some seconds, so we do it in background to keep the UI responsive.
            self.imageView.image = nil
            self.spinner.startAnimating()

            let value = self.value
            DispatchQueue.global().async { [weak self] in
                let image = UIImage.generateQRCode(value: value, size: .init(width: 300, height: 300))

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
        layer.borderWidth = 2
        layer.borderColor = UIColor.gray4.cgColor
        layer.cornerRadius = 10
    }

}
