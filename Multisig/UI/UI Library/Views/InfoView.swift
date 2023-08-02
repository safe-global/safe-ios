//
//  InfoView.swift
//  Multisig
//
//  Created by Mouaz on 6/20/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoView: UINibView {
    enum Status {
        case loading
        case success
    }

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    private var status: Status = .success

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 8
        textLabel.setStyle(.subheadline1Medium)
    }

    func set(text: String, background: UIColor = .backgroundLightGreen, status: Status? = nil, textStyle: GNOTextStyle = .subheadline1Medium) {
        textLabel.text = text
        textLabel.setStyle(textStyle)
        self.backgroundColor = background
        if let status = status {
            set(status: status)
        }

        layoutIfNeeded()
    }

    func set(status: Status) {
        self.status = status
        switch status {
        case .loading:
            imageView.image = UIImage(named: "ico-spinning")?.withTintColor(.labelSecondary)
            imageView.rotate()
        case .success:
            imageView.stopRotate()
            imageView.image = UIImage(named: "ico-check-green")
            imageView.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in 
                self?.imageView.alpha = 1
            }, completion: nil)
        }
    }
}

extension UIView{
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        layer.add(rotation, forKey: "rotationAnimation")
    }

    func stopRotate() {
        layer.removeAnimation(forKey: "rotationAnimation")
        layer.removeAllAnimations()
    }
}
