//
//  WordView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class WordView: UINibView {
    @IBOutlet weak var wordLabel: UILabel!
    // Used to draw the dashed border using the CoreAnimation
    var borderLayer: CAShapeLayer!

    // Parameters of the border
    let borderWidth: CGFloat = 1
    let cornerRadius: CGFloat = 8

    var didTap: (() -> Void)?

    override func commonInit() {
        super.commonInit()
        wordLabel.setStyle(.subheadline)
        borderLayer = CAShapeLayer()
        layer.addSublayer(borderLayer)
        style = .normal

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapWord)))
    }

    enum Style {
        case empty
        case normal
        case correct
        case incorrect
        case checking
    }

    var style: Style = .normal {
        didSet {
            self.updateAppearance()
        }
    }

    func updateAppearance() {
        var borderColor: UIColor = .border
        var dashLength: CGFloat? = nil

        backgroundColor = .backgroundSecondary

        switch style {
        case .empty:
            dashLength = 6
            backgroundColor = .backgroundPrimary
        case .normal:
            // nothing to do
            break
        case .correct:
            borderColor = .primary
        case .incorrect:
            borderColor = .error
        case .checking:
            borderColor = .border
        }

        layer.cornerRadius = cornerRadius

        borderLayer.frame = layer.bounds
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.lineDashPattern = dashLength.map { [NSNumber(value: $0), NSNumber(value: $0)] }

        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = CGMutablePath(
            roundedRect: layer.bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil)
        borderLayer.path = path
        borderLayer.frame = layer.bounds
    }

    @objc private func didTapWord() {
        didTap?()
    }
}
