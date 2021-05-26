//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit


class SeedWordCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false

        numberLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        numberLabel.textAlignment = .center

        wordLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        wordLabel.textAlignment = .center
        wordLabel.adjustsFontSizeToFitWidth = true
        wordLabel.minimumScaleFactor = 0.5
        update()
    }

    var word: SeedWord? {
        didSet {
            update()
        }
    }

    func update() {
        wordLabel.text = word?.value
        numberLabel.text = word?.number
        numberLabel.textColor = .primaryLabel
        badgeImageView.image = UIImage(named: "seed-badge-normal")
        wordLabel.textColor = .button
        backgroundImageView.image = UIImage(named: "seed-bg-normal")
    }

}
