//
//  BackupLoadSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class BackupLoadSafeViewController: UIViewController {

    @IBOutlet private weak var callToActionLabel: UILabel!
    @IBOutlet private weak var loadSafeButton: UIButton!
    private var buttonYConstraint: NSLayoutConstraint?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        callToActionLabel.setStyle(.title3)
        loadSafeButton.setText("Load Safe", .filled)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // center the button relative to the window instead of containing view
        // because this screen is used several times in different tabs
        // and the Y position of this view will be different -> leading to
        // the visual jumps when switching the tabs.
        if let window = view.window, buttonYConstraint == nil || buttonYConstraint?.isActive == false {
            buttonYConstraint = loadSafeButton.centerYAnchor.constraint(equalTo: window.centerYAnchor)
            buttonYConstraint?.isActive = true
            view.setNeedsLayout()
        }
    }

    // UIKit: need to manually remember this controller because
    // it won't be provided in `presentedViewController` when this
    // view controller is a child of another view controller.
    var presentedVC: UIViewController?

    @IBAction func didTapLoadSafe(_ sender: Any) {
        presentedVC = ViewControllerFactory.loadSafeController(presenter: self)
        present(presentedVC!, animated: true, completion: nil)
    }

    override func closeModal() {
        presentedVC?.dismiss(animated: true, completion: nil)
        presentedVC = nil
    }

}
