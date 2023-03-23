//
//  ChoosePaymentViewController.swift
//  Multisig
//
//  Created by Vitaly on 23.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChoosePaymentViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Choose how to pay"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.relayChoosePayment)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}
