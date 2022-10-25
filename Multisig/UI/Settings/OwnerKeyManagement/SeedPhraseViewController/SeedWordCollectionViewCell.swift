//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit

class SeedWordCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = false

        numberLabel.setStyle(.callout)

        wordLabel.setStyle(.calloutPrimary)
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
    }
}
