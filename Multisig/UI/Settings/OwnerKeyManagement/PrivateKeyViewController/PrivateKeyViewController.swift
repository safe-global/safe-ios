//
//  PrivateKeyViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PrivateKeyViewController: UIViewController {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var privateKeyLabel: UILabel!
    @IBOutlet weak var qrCodeView: QRCodeView!

    var privateKey: String = ""

    var showsHeader: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        headerLabel.isHidden = !showsHeader

        headerLabel.setStyle(.title2)
        privateKeyLabel.setStyle(.headline)

        privateKeyLabel.text = privateKey
        qrCodeView.value = privateKey
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.exportKey)
    }

}
