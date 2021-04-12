//
//  BigImageWithTextButtonView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class BigImageWithTextButtonView: UINibView {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var label: UILabel!

    var onSecect: (() -> Void)?

    @IBAction private func tap(_ sender: Any) {
        onSecect?()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray2.cgColor

        label.setStyle(.headline)
    }

    func set(image: UIImage) {
        imageView.image = image
    }

    func set(text: String) {
        label.text = text
    }
}
