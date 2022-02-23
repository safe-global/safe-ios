//
//  SafeDeploymentFinishedViewController.swift
//  Multisig
//
//  Created by Vitaly on 23.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class SafeDeploymentFinishedViewController: UIViewController {

    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var linkButton: UIButton!
    
    enum Mode {
        case success
        case failure
    }
    
    private var mode: Mode = .failure
    
    convenience init(mode: Mode) {
        self.init(nibName: nil, bundle: nil)
        self.mode = mode
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.tertiary)
        
        switch mode {
        case .success:
            statusImage.image = UIImage(named: "ico-safe-deployment-success")
            titleLabel.text = "Your Safe is ready!"
            descriptionLabel.text = "That’s it! Start using your most secure wallet on Ethereum."
            actionButton.setText("Start using Safe", .filled)
            break
        case .failure:
            statusImage.image = UIImage(named: "ico-safe-deployment-failure")
            titleLabel.text = "Oops, Safe wasn’t created"
            descriptionLabel.text = "Safe couldn’t have been created. This might happen due to the mining error or spiked gas fees."
            actionButton.setText("Retry", .filled)
            linkButton.setText("View Transaction on Etherscan", .plain)
            break
        }
    }
    
    func present() {
        let finishedVC = SafeDeploymentFinishedViewController()
        let vc = ViewControllerFactory.pageSheet(viewController: finishedVC, halfScreen: true)
        present(vc, animated: true)
    }
    
    @IBAction func didTapActionButton(_ sender: Any) {
    }
}
