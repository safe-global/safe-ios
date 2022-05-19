//
//  BasicCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 05.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import Kingfisher

class BasicCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var disclosureImageView: UIImageView!
    @IBOutlet private weak var supplementaryImageView: UIImageView!

    static let rowHeight: CGFloat = 60

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.primary)
        detailLabel.setStyle(.secondary)
        setDetail(nil)
        setSupplementary(nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setDetail(nil)
        setSupplementary(nil)
        setDisclosureImage(UIImage(named: "arrow"))
    }

    func setTitle(_ value: String?, style: GNOTextStyle = .primary) {
        titleLabel.text = value
        titleLabel.setStyle(style)
    }
    
    func setIcon(_ value: String?, tintColor: UIColor? = nil) {
        guard let value = value else {
            iconImage.isHidden = true
            return
        }
        let image = UIImage(named: value) ?? UIImage(systemName: value)
        iconImage.image = image
        iconImage.isHidden = false
        iconImage.tintColor = tintColor
    }

    func setIcon(url: URL?, placeholder: UIImage? = nil) {
        iconImage.kf.setImage(with: url, placeholder: placeholder)
    }

    func setDetail(_ value: String?) {
        detailLabel.text = value
    }

    func setDisclosureImage(_ image: UIImage?) {
        disclosureImageView.image = image
    }

    func setDisclosureImageTintColor(_ tintColor: UIColor) {
        disclosureImageView.tintColor = tintColor
    }

    func setSupplementary(_ image: UIImage? = nil) {
        supplementaryImageView.image = image
        supplementaryImageView.isHidden = image == nil
    }
}
