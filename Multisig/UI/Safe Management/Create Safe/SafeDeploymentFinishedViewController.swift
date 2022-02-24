//
//  SafeDeploymentFinishedViewController.swift
//  Multisig
//
//  Created by Vitaly on 23.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import UnstoppableDomainsResolution

class SafeDeploymentFinishedViewController: UIViewController {

    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var labelContainer: UIStackView!
    
    enum Mode {
        case success
        case failure
    }
    
    private var mode: Mode = .failure
    private var chain: Chain = Chain.mainnetChain()
    private var txHash: String?
    
    convenience init(mode: Mode, chain: Chain) {
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
            linkButton.isHidden = true
            break
            
        case .failure:
            statusImage.image = UIImage(named: "ico-safe-deployment-failure")
            titleLabel.text = "Oops, Safe wasn’t created"
            descriptionLabel.text = "Safe couldn’t have been created. This might happen due to the mining error or spiked gas fees."
            labelContainer.layoutMargins = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
            
            actionButton.setText("Retry", .filled)
            linkButton.setText("View on block explorer", .plain)
            
            NSLayoutConstraint.activate([
                
                NSLayoutConstraint(item: self.statusImage!, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: -32),

                NSLayoutConstraint(item: self.labelContainer!, attribute: .top, relatedBy: .equal, toItem: self.statusImage, attribute: .bottom, multiplier: 1, constant: 32)
            ])
            
            break
        }
    }
    
    func present() {
        let finishedVC = SafeDeploymentFinishedViewController()
        let vc = ViewControllerFactory.pageSheet(viewController: finishedVC, halfScreen: true)
        present(vc, animated: true)
    }
    
    @IBAction func didTapActionButton(_ sender: Any) {
        switch mode {
        case .success:
            break
        case .failure:
//            guard let txHash = txHash else {
//                return
//            }
            let url = chain.browserURL(address: "0ac16324cdba5d60bda9f16900469d29a600d5759b81d60018b59456fb0df3b7")
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            break
        }
    }
}
