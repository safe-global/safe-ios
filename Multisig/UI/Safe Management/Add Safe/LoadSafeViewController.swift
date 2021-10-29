//
//  LoadSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadSafeViewController: UIViewController {

    var trackingEvent: TrackingEvent?
    @IBOutlet private weak var callToActionLabel: UILabel!
    @IBOutlet private weak var loadSafeButton: UIButton!
    private var buttonYConstraint: NSLayoutConstraint?

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        callToActionLabel.setStyle(.title3)
        loadSafeButton.setText("Load Gnosis Safe", .filled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let event = trackingEvent {
            Tracker.trackEvent(event)
        }
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

    @IBAction private func didTapLoadSafe(_ sender: Any) {
        let vc = SelectNetworkViewController()
        vc.screenTitle = "Load Gnosis Safe"
        vc.descriptionText = "Select network on which your Safe was created:"
        vc.completion = { [weak self] chain  in
            let vc = EnterSafeAddressViewController()
            vc.chain = chain
            let ribbon = RibbonViewController(rootViewController: vc)
            ribbon.chain = vc.chain
            vc.completion = { self?.navigationController?.popToRootViewController(animated: true) }
            self?.show(ribbon, sender: self)
        }

        show(vc, sender: self)
    }
}
