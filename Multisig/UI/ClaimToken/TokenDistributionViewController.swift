//
//  TokenDistributionViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/5/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TokenDistributionViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet weak var distributionView: BorderedCheveronButton!

    private var onNext: (() -> ())?

    convenience init(onNext: @escaping () -> ()) {
        self.init(namedClass: TokenDistributionViewController.self)
        self.onNext = onNext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.trackEvent(.screenClaimDistr)

        ViewControllerFactory.removeNavigationBarBorder(self)
        navigationItem.largeTitleDisplayMode = .never
        distributionView.set("Distribution details") { [unowned self] in
            Tracker.trackEvent(.userClaimDistrDetails)

            let content: [(title: String?, description: String?)] = [
                (title: "60% — Community Treasuries", description: "40% SafeDAO Treasury\n15% GnosisDAO Treasury\n5% Joint Treasury (GNO <> SAFE)"),
                (title: "15% — Core Contributors", description: "Current and future core contributor teams"),
                (title: "15% — Safe Foundation", description: "8% strategic raise\n7% grants and reserve"),
                (title: "5% — Ecosystem (Guardians)", description: "1.25% allocation\n1.25% vested allocation\n2.5% future programs"),
                (title: "5% — User", description: "2.5% allocation\n2.5% vested allocation")]
            let vc = ViewControllerFactory.modal(viewController: DetailedInfoListViewController(title: "Distribution details",
                                                                                                content: content,
                                                                                                trackingEvent: .screenClaimDistrDetail))
            present(vc, animated: true)
        }
        titleLabel.setStyle(.title2)
        descriptionLabel.setStyle(.body)
        nextButton.setText("Next", .filled)
    }

    @IBAction func didTapNext(_ sender: Any) {
        Tracker.trackEvent(.userClaimDistrNext)
        onNext?()
    }
}
