//
//  NoScreenshotViewController.swift
//  Multisig
//
//  Created by Vitaly on 14.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class NoScreenshotViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    
    static func show(presenter: UIViewController) {
        let vc = NoScreenshotViewController()
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        presenter.present(vc, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundView.layer.cornerRadius = 15
        titleLabel.setStyle(.headline)
        descriptionLabel.setStyle(.body)
        okButton.setText("OK, I understand", .filled)
    }
    
    @IBAction func didTapOk(_ sender: Any) {
        dismiss(animated: true)
    }
}
