//
//  ShareTextView.swift
//  Multisig
//
//  Created by Moaaz on 6/13/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ShareTextView: UINibView {

    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    var onShare: ((String) -> ())?
    private var textToShare: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 2
        layer.cornerRadius = 10
        textLabel.setStyle(.body)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = UIColor.border.cgColor
    }

    func set(text: String) {
        textLabel.text = text
        textToShare = text
    }

    @IBAction private func shareButtonTouched(_ sender: Any) {
        guard let textToShare = textToShare else { return }
        onShare?(textToShare)
    }
}
