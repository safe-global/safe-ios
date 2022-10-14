//
//  CollectibleDetailViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectibleDetailViewController: UIViewController {
    @IBOutlet private weak var imageContainerView: UIView!
    @IBOutlet private weak var imageView: WebImageView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    @IBOutlet weak var addressView: AddressInfoView!

    var collectible: CollectibleViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Collectible Details"
        titleLabel.setStyle(.headline)
        detailLabel.setStyle(.callout)
        descriptionLabel.setStyle(.body)

        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true

        titleLabel.text = collectible.name
        detailLabel.text = collectible.tokenID
        descriptionLabel.text = collectible.description

        if let url = collectible.imageURL {
            imageView.setImage(url: url, placeholder: UIImage(named: "ico-collectible-placeholder"), onError: { [weak self] in
                self?.imageContainerView.isHidden = true
            })
        }
        imageContainerView.isHidden = collectible.imageURL == nil

        addressView.setAddress(.init(exactly: collectible.address), label: "Asset Contract")
    }
}
