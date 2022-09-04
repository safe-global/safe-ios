//
//  WhatIsSafeViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 02.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WhatIsSafeViewController: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var content1: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()


        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)
        //ViewControllerFactory. // show step 1/4 in the top right corner

        nextButton.setText("Next", .filled)

        titleLabel.text = "What is Safe?"
        content1.text = """
                        Safe is critical infrastructure for web3.  It is a programmable account standard that enables secure management of digital assets, data and identity.

                        With this token launch, Safe is now a community-driven ownership platform.
                        """

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
