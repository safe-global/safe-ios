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
    @IBOutlet weak var labelContainer: UIStackView!
    
    @IBOutlet weak var labelContainerTop: NSLayoutConstraint!
    @IBOutlet weak var statusImageTop: NSLayoutConstraint!

    enum Mode {
        case success
        case failure
    }
    
    private var mode: Mode = .success
    private var chain: Chain!
    private var txHash: String?
    private var safe: Safe?
    
    var onRetry: () -> Void = {}
    var onClose: () -> Void = {}
    
    convenience init(mode: Mode, chain: Chain, txHash: String?, safe: Safe? = nil) {
        self.init(nibName: nil, bundle: nil)
        self.mode = mode
        self.chain = chain
        self.txHash = txHash
        self.safe = safe
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

        case .failure:
            statusImage.image = UIImage(named: "ico-safe-deployment-failure")
            titleLabel.text = "Oops, Safe wasn’t created"
            descriptionLabel.text = "Safe couldn’t have been created. This might happen due to the mining error or spiked gas fees."
            
            actionButton.setText("Retry", .filled)
            linkButton.setText("View on block explorer", .plain)

            statusImageTop.constant = -16
            labelContainerTop.constant = 32
            view.setNeedsUpdateConstraints()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onClose()
    }
    
    static func present(
        presenter: UIViewController,
        mode: Mode,
        chain: Chain,
        txHash: String? ,
        safe: Safe? = nil,
        onClose: @escaping () -> Void,
        onRetry: @escaping () -> Void
    ) {
        let finishedVC = SafeDeploymentFinishedViewController(mode: mode, chain: chain, txHash: txHash, safe: safe)
        finishedVC.onRetry = onRetry
        finishedVC.onClose = onClose
        let vc = ViewControllerFactory.pageSheet(viewController: finishedVC, halfScreen: true)
        presenter.present(vc, animated: true)
    }
    
    @IBAction func didTapActionButton(_ sender: Any) {
        
        switch mode {
            
        case .success:
            // select deployed safe
            if let safe = safe {
                safe.select()
            }

            dismiss(animated: true, completion: nil)
            
        case .failure:
            // retry safe deployment transaction
            dismiss(animated: true, completion: nil)
            onRetry()
        }
    }
    
    @IBAction func didTapViewOnBlockExplorer(_ sender: Any) {

        guard let txHash = txHash else {
            return
        }
        
        let url = chain.browserURL(txHash: txHash)
        openInSafari(url)
    }
}
