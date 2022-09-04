//
//  TutorialScreenCollectionViewCell.swift
//  Multisig
//
//  Created by Dirk Jäckel on 04.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TutorialScreenCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

    static let identifier = "TutorialScreenCollectionViewCell"

    func configure(step: TutorialScreen) {
        titleLabel.text = step.title
        titleLabel.setStyle(.Updated.title)
        descriptionLabel.text = step.description
        descriptionLabel.setStyle(.secondary)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }


}

//TODO needs to have a collection of TutorialScreenSections.
struct TutorialScreen {
    let title: String
    let description: String
}

// TODO section can be one of: screen title, section title, paragraph, highlighted paragraph, graphic, Button
class TutorialScreenSections {

}