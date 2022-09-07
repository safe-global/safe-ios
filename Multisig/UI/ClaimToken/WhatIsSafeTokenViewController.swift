//
//  WhatIsSafeViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WhatIsSafeTokenViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var safeProtocolView: BorderedCheveronButton!
    @IBOutlet private weak var interfacesView: BorderedCheveronButton!
    @IBOutlet private weak var assetsView: BorderedCheveronButton!
    @IBOutlet private weak var tokenomicsView: BorderedCheveronButton!
    @IBOutlet private weak var tokenNonTrnasferableLabel: UILabel!

    private var onNext: (() -> ())?


    convenience init(onNext: @escaping () -> ()) {
        self.init(namedClass: WhatIsSafeTokenViewController.self)
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.removeNavigationBarBorder(self)

        safeProtocolView.set("Safe Protocol") { [unowned self] in
            let vc = ViewControllerFactory.detailedInfoViewController(title: "Safe Protocol",
                                                                      text: "Safe Deployments (core smart contract deployments across multiple networks\nCuration of “trusted lists” (Token lists, dApp lists, module lists)",
                                                                      attributedText: nil)
            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        interfacesView.set("Interfaces") { [unowned self] in
            let vc = ViewControllerFactory.detailedInfoViewController(title: "Interfaces",
                                                                      text: "Decentralized hosting of a Safe frontend using the safe.eth domain\nDecentralized hosting of governance frontends",
                                                                      attributedText: nil)
            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        assetsView.set("On-chain assets") { [unowned self] in
            let vc = ViewControllerFactory.detailedInfoViewController(title: "On-chain assets",
                                                                      text: "ENS names\nOutstanding Safe token supply\nOther Safe Treasury assets (NFTs, tokens, etc.)",
                                                                      attributedText: nil)
            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        tokenomicsView.set("Tokenomics") { [unowned self] in
            let vc = ViewControllerFactory.detailedInfoViewController(title: "Tokenomics",
                                                                      text: "Ecosystem reward programs\nUser rewards\nValue capture\nFuture token utility",
                                                                      attributedText: nil)

            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        tokenNonTrnasferableLabel.setStyle(.callout.color(.labelSecondary))
        titleLabel.setStyle(.Updated.title)
        descriptionLabel.setStyle(.secondary)
        nextButton.setText("Next", .filled)
    }

    @IBAction func didTapNext(_ sender: Any) {
        onNext?()
    }
}

extension WhatIsSafeTokenViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        PresentationController(presentedViewController: presented, presenting: presenting)
    }
}
