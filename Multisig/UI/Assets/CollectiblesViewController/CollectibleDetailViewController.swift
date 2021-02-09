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
    @IBOutlet private weak var svgView: SVGView!

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    @IBOutlet weak var addressView: AddressInfoView!

    var collectible: CollectibleViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Collectible Details"
        titleLabel.setStyle(.headline)
        detailLabel.setStyle(.footnote2)
        descriptionLabel.setStyle(.body)

        svgView.layer.cornerRadius = 10
        svgView.clipsToBounds = true

        titleLabel.text = collectible.name
        detailLabel.text = collectible.tokenID
        descriptionLabel.text = collectible.description

        if let url = collectible.imageURL {
            svgView.setImage(url: url, placeholder: #imageLiteral(resourceName: "ico-collectible-placeholder"), onError: { [weak self] in
                self?.imageContainerView.isHidden = true
            })
        }
        imageContainerView.isHidden = collectible.imageURL == nil

        addressView.setAddress(.init(exactly: collectible.address), label: "Asset Contract", imageUri: nil)
    }

}
