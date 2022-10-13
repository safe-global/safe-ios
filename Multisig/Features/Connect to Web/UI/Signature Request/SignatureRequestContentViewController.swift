//
//  SignatureRequestContentViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class SignatureRequestContentViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var signerAddressView: TitledMiniPieceView!

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.setStyle(.headline)
        detailsLabel.setStyle(.body)
    }
}
