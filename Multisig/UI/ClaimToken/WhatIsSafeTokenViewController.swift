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
        Tracker.trackEvent(.screenClaimGov)

        ViewControllerFactory.removeNavigationBarBorder(self)

        safeProtocolView.set("Safe Protocol") { [unowned self] in
            Tracker.trackEvent(.userClaimGovProto)

            let content: [(title: String?, description: String?)] = [
                (title: nil, description: "Safe Deployments (core smart contract deployments across multiple networks)\nCuration of “trusted lists” (Token lists, dApp lists, module lists)")]
            let vc = DetailedInfoListViewController(title: "Safe protocol", content: content)

            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        interfacesView.set("Interfaces") { [unowned self] in
            Tracker.trackEvent(.userClaimGovInterface)

            let content: [(title: String?, description: String?)] = [
                (title: nil, description: "Decentralized hosting of a Safe frontend using the safe.eth domain\nDecentralized hosting of governance frontends")]
            let vc = DetailedInfoListViewController(title: "Interfaces", content: content)

            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        assetsView.set("On-chain assets") { [unowned self] in
            Tracker.trackEvent(.userClaimGovAssets)

            let content: [(title: String?, description: String?)] = [
                (title: nil, description: "ENS names\nOutstanding Safe token supply\nOther Safe Treasury assets (NFTs, tokens, etc.)")]
            let vc = DetailedInfoListViewController(title: "On-chain assets", content: content)

            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        tokenomicsView.set("Tokenomics") { [unowned self] in
            Tracker.trackEvent(.userClaimGovToken)

            let content: [(title: String?, description: String?)] = [
                (title: nil, description: "Ecosystem reward programs\nUser rewards\nValue capture\nFuture token utility")]
            let vc = DetailedInfoListViewController(title: "Tokenomics", content: content)

            let viewController = ViewControllerFactory.modal(viewController: vc, halfScreen: true)
            present(viewController, animated: true)
        }

        tokenNonTrnasferableLabel.setStyle(.callout.color(.labelSecondary))
        titleLabel.setStyle(.title2)
        descriptionLabel.setStyle(.body)
        nextButton.setText("Next", .filled)
    }

    @IBAction func didTapNext(_ sender: Any) {
        Tracker.trackEvent(.userClaimGovNext)
        onNext?()
    }
}

