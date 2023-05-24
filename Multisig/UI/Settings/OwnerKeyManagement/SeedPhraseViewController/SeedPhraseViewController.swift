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
        infoLabel.setStyle(.body)

        warningView.set(description: "Safe{Wallet} will never ask for your seed phrase! It is encrypted and stored locally on your device.")

        copyToClipboardButton.setText("Export", .primary)

        seedPhraseView.words = seedPhrase.enumerated().map {
            SeedWord(index: $0.offset, value: $0.element)
        }
    }

    @IBAction func didTapCopyButton(_ sender: Any) {
        export(seedPhrase.joined(separator: " "))
    }

    func export(_ value: String) {
        Tracker.trackEvent(.backupUserCopiedSeedPhrase)
        let vc = UIActivityViewController(activityItems: [value], applicationActivities: nil)
        present(vc, animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        seedPhraseView.update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(screenshotTaken), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
        Tracker.trackEvent(trackingEvent)
        seedPhraseView.update()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenshotTaken() {
        Tracker.trackEvent(.backupUserSeedPhraseScreenshot)
        NoScreenshotViewController.show(presenter: self)
    }
}

struct SeedWord {
    var index: Int
    var value: String

    var number: String {
        return String(index + 1)
    }
}
