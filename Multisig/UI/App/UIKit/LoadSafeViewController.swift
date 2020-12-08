//
//  LoadSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadSafeViewController: UIViewController {
    var trackingEvent: TrackingEvent?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let trackingEvent = trackingEvent else { return }
        trackEvent(trackingEvent)
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
