//
//  SafeDeploymentFinishedViewController.swift
//  Multisig
//
//  Created by Vitaly on 23.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeDeploymentFinishedViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func present() {
        let finishedVC = SafeDeploymentFinishedViewController()
        let vc = ViewControllerFactory.pageSheet(viewController: finishedVC, halfScreen: true)
        present(vc, animated: true)
    }
}
