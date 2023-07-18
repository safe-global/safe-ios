//
//  InfoBoxView.swift
//  Multisig
//
//  Created by Vitaly on 15.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoBoxView: UINibView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var actionContainer: UIStackView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var beta: UIImageView!

    private var onActionPrimary: (() -> ())? = nil
    private var onActionSecondary: (() -> ())? = nil
    private var actionSecondary: String? = nil


    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundView.layer.cornerRadius = 6
        backgroundView.backgroundColor = .infoBackground
        messageLabel.setStyle(.callout)
    }

    func setText(_ text: String, showBeta: Bool = false) {
        messageLabel.text = text
        beta.isHidden = !showBeta
    }

    func setText(_ text: String,
                 backgroundColor: UIColor = .infoBackground,
                 hideIcon: Bool = false,
                 icon: UIImage? = nil,
                 showBeta: Bool = false
    ) {
        setText(
            NSAttributedString(string: text),
            backgroundColor: backgroundColor,
            hideIcon: hideIcon,
            icon: icon,
            showBeta: showBeta
        )
    }

    func setText(_ text: NSAttributedString,
                 backgroundColor: UIColor = .infoBackground,
                 hideIcon: Bool = false,
                 icon: UIImage? = nil,
                 showBeta: Bool = false
    ) {
        messageLabel.attributedText = text
        backgroundView.backgroundColor = backgroundColor
        iconImageView.isHidden = hideIcon
        if let icon = icon {
            iconImageView.image = icon
        }
        beta.isHidden = !showBeta
    }

    func addActionSecondary(title: String, action: (() -> ())?) {
        guard let text = messageLabel.attributedText else { return }
        messageLabel.hyperLinkLabel(
            text.string,
            prefixStyle: .body,
            linkText: title,
            linkStyle: .button,
            linkIcon: nil,
            underlined: false
        )
        actionSecondary = title
        onActionSecondary = action
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(didTapActionSecondary(_ :)))
        tapgesture.numberOfTapsRequired = 1
        messageLabel.isUserInteractionEnabled = true
        messageLabel.addGestureRecognizer(tapgesture)
    }

    @objc func didTapActionSecondary(_ gesture: UITapGestureRecognizer) {
        guard let text = messageLabel.text else { return }
        guard let actionSecondary = self.actionSecondary else { return }
        let actionSecondaryRange = (text as NSString).range(of: actionSecondary)
        if gesture.didTapAttributedTextInLabel(label: messageLabel, inRange: actionSecondaryRange) {
            self.onActionSecondary?()
        }
    }

    func addActionPrimary(title: String, action: (() -> ())?) {
        actionButton.setText(title, .plain)
        actionContainer.isHidden = false
        onActionPrimary = action
    }

    @IBAction func didTapActionPrimary(_ sender: Any) {
        onActionPrimary?()
    }
}
