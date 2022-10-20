//
//  ExternalURLCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 03.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExternalURLCell: UITableViewCell, ExternalURLSource {
    @IBOutlet private weak var button: UIButton!
    private(set) var url: URL?
    override func awakeFromNib() {
        super.awakeFromNib()
        button.titleLabel?.setStyle(.headline)
    }

    func setText(_ text: String, url: URL) {
        button.setTitle(text, for: .normal)
        self.url = url
    }
    
    @IBAction func didTapButton(_ sender: Any) {
        openExternalURL()
    }
}
