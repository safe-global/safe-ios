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

    @IBAction private func didTapButton(_ sender: Any) {
        do {
            guard
                let safe = try Safe.getSelected(),
                safe.hasAddress,
                let chainId = safe.chain?.id,
                let url = WebAppURLBuilder.url(chain: chainId, safe: safe.addressValue)
            else { return }

            if UIApplication.shared.canOpenURL(url) {
                 UIApplication.shared.open(url)
            }
        } catch {
            LogService.shared.error("Failed to get selected safe: \(error)")
        }
    }
}
