//
//  BackupSeedPhraseViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

 
class BackupSeedPhraseViewController: ContainerViewController {
    
    @IBOutlet weak var seedPhraseContentView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    
    var seedPhraseViewController: SeedPhraseViewController!
    
    var seedPhrase: [String] = []
    
    var onContinue: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Back up manually"
        
        seedPhraseViewController = SeedPhraseViewController()
        seedPhraseViewController.seedPhrase = seedPhrase
        seedPhraseViewController.trackingEvent = .backupVerifySeedPhrase
        seedPhraseViewController.infoText = "Make sure to store your seed phrase in a secure place. You will need to verify it in the next step."
        
        viewControllers = [seedPhraseViewController]
        
        displayChild(at: 0, in: seedPhraseContentView)
       
        continueButton.setText("Continue", .filled)
    }

    func set(mnemonic: String) {
        seedPhrase = mnemonic.split(separator: " ").compactMap(String.init)
    }

    @IBAction func didTapContinueButton(_ sender: Any) {
        onContinue?()
    }
}
