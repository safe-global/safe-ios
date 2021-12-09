//
//  CollectiblesUnsupportedViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class CollectiblesUnsupportedViewController: UIViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var bodyText: UILabel!
    @IBOutlet private weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        bodyText.setStyle(.title3)
        button.setText("View in Browser", .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.collectiblesNotSupported)
    }

    @IBAction private func didTapButton(_ sender: Any) {
        do {
            guard
                let safe = try Safe.getSelected(),
                safe.hasAddress,
                let chainPrefix = safe.chain?.shortName,
                let url = WebAppURLBuilder.url(safe: safe.addressValue, chainPrefix: chainPrefix)
            else { return }

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                Tracker.trackEvent(.collectiblesOpenInWeb)
            }
        } catch {
            LogService.shared.error("Failed to get selected safe: \(error)")
        }
    }
}
