//
//  CardTableViewCell.swift
//  Multisig
//
//  Created by Moaaz on 1/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CardTableViewCell: UITableViewCell, ExternalURLSource {
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var linkButton: UIButton!

    private(set) var url: URL?

    @IBAction func openUrl(_ sender: Any) {
        openExternalURL()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        bodyLabel.setStyle(.body)
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        linkLabel.isHidden = false
        linkButton.isHidden = false
    }

    func set(image: UIImage?) {
        iconImageView.image = image
    }

    func set(title: String) {
        titleLabel.text = title
    }
    
    func set(body: String) {
        bodyLabel.text = body
    }

    func set(linkTitle: String?, url: URL?) {
        guard let linkTitle = linkTitle,
              let url = url else {
            linkLabel.isHidden = true
            linkButton.isHidden = true
            return
        }
        linkLabel.hyperLinkLabel(linkText: linkTitle)
        self.url = url
    }
}
