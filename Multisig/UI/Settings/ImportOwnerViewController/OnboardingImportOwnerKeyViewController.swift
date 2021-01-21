//
//  OnboardingImportOwnerKeyViewController.swift
//  Multisig
//
//  Created by Moaaz on 1/21/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingImportOwnerKeyViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let cards = [(UIImage(named: "ico-onbaording-import-key-1"), "How does it work?", "Enter the private key or seed phrase of your owner key controlling your Safe. Your owner key will be imported into this app. You can then confirm proposed transactions on the go. "),
                         (UIImage(named: "ico-onbaording-import-key-2"), "How secure is that?", "We only store your private key. We do not store your seed phrase in the app. "),
                         (UIImage(named: "ico-onbaording-import-key-3"), "Is my wallet supported?", "Only MetaMask and hardware wallets are supported. Importing the key will not import the assets from your MetaMask or hardware wallet.")]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension OnboardingImportOwnerKeyViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(<#T##aClass: T.Type##T.Type#>)

        return cell
    }
}
