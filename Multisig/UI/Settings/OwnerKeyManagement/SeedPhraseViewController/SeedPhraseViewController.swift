//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit

class SeedPhraseViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var seedPhraseView: SeedPhraseView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningContent: UIStackView!
    @IBOutlet weak var warningIcon: UIImageView!
    @IBOutlet weak var copyToClipboardButton: UIButton!

    var seedPhrase: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.text = "Make sure to store your seed phrase in a secure place."
        infoLabel.setStyle(.secondary)

        warningIcon.tintColor = .orange

        warningContent.backgroundColor = .backgroundWarning

        warningLabel.text = "Gnosis Safe will never ask for your seed phrase! It is encrypted and stored locally on your device."
        warningLabel.setStyle(.secondary)

        copyToClipboardButton.setText("Copy to Clipboard", .primary)
        copyToClipboardButton.imageView?.image = UIImage(named: "ico-copy")


        seedPhraseView.words = seedPhrase.enumerated().map {
            SeedWord(index: $0.offset, value: $0.element)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        seedPhraseView.update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.exportSeed)
    }

}

struct SeedWord {
    var index: Int
    var value: String

    var number: String {
        return String(index + 1)
    }
}
