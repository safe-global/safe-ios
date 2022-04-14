//
//  BackupSeedPhraseViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

//FIXME: extract base functionality from BackupSeedPhraseViewController and SeedPhraseViewController to a base class
class BackupSeedPhraseViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var seedPhraseView: SeedPhraseView!
    @IBOutlet weak var warningView: WarningView!
    @IBOutlet weak var copyToClipboardButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    var seedPhrase: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Back up manually"
        
        infoLabel.text = "Make sure to store your seed phrase in a secure place. You will need to verify it in the next step."
        infoLabel.setStyle(.secondary)

        warningView.set(description: "Gnosis Safe will never ask for your seed phrase! It is encrypted and stored locally on your device.")

        copyToClipboardButton.setText("Copy to Clipboard", .primary)

        seedPhraseView.words = seedPhrase.enumerated().map {
            SeedWord(index: $0.offset, value: $0.element)
        }
        
        continueButton.setText("Continue", .filled)
        
        NotificationCenter.default.addObserver(self, selector: #selector(screenshotTaken), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    @objc private func screenshotTaken() {
        NoScreenshotViewController.show(presenter: self)
    }
    
    @IBAction func didTapContinueButton(_ sender: Any) {
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
        Tracker.trackEvent(.exportSeed)
        seedPhraseView.update()
    }
}
