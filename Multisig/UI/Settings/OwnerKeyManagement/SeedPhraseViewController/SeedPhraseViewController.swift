//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import UIKit

class SeedPhraseViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var seedPhraseView: SeedPhraseView!
    @IBOutlet weak var warningView: WarningView!
    @IBOutlet weak var copyToClipboardButton: UIButton!

    var infoText = "Make sure to store your seed phrase in a secure place."
    var seedPhrase: [String] = []
    var trackingEvent: TrackingEvent = .exportSeed

    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.text = infoText
        infoLabel.setStyle(.secondary)

        warningView.set(description: "Gnosis Safe will never ask for your seed phrase! It is encrypted and stored locally on your device.")

        copyToClipboardButton.setText("Copy to Clipboard", .primary)

        seedPhraseView.words = seedPhrase.enumerated().map {
            SeedWord(index: $0.offset, value: $0.element)
        }
    }

    @IBAction func didTapCopyButton(_ sender: Any) {
        export(seedPhrase.joined(separator: " "))
    }

    func export(_ value: String) {
        let vc = UIActivityViewController(activityItems: [value], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        seedPhraseView.update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(trackingEvent)
        seedPhraseView.update()
    }
}

struct SeedWord {
    var index: Int
    var value: String

    var number: String {
        return String(index + 1)
    }
}
