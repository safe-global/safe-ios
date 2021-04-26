//
//  WCPedingConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class WCPedingConfirmationViewController: UIViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!

    @IBAction func cancel(_ sender: Any) {
        close()
    }

    static func create() -> WCPedingConfirmationViewController {
        let controller = WCPedingConfirmationViewController(nibName: "WCPedingConfirmationViewController", bundle: Bundle.main)
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        topView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))

        // round top corners
        bottomView.layer.cornerRadius = 10
        bottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        headerLabel.setStyle(.headline)
        activityIndicator.startAnimating()
        descriptionLabel.setStyle(.callout)
        cancelButton.setText("Cancel", .filledError)

        modalTransitionStyle = .crossDissolve
    }

    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
}
