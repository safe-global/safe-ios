//
//  HyperlinkButtonView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class HyperlinkButtonView: UINibView, ExternalURLSource {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!

    var url: URL?

    func setText(_ value: String?) {
        label.text = nil
        if let text = value {
            label.hyperLinkLabel(linkText: text)
        } else {
            label.attributedText = nil
        }
        button.setTitle("", for: .normal)
    }

    @IBAction func didTapButton(_ sender: Any) {
        openExternalURL()
    }
}
