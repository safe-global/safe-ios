//
//  LoadSafeViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class LoadSafeViewController: UIViewController {

    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var loadSafeButton: UIButton!
    @IBOutlet private weak var createSafeButton: UIButton!
    @IBOutlet private weak var demoButton: UIButton!

    private var buttonYConstraint: NSLayoutConstraint?
    var trackingEvent: TrackingEvent?
    var createSafeFlow: CreateSafeFlow!

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.setStyle(.title3)
        descriptionLabel.setStyle(.callout)
        loadSafeButton.setText("Load existing Safe Account", .filled)
        createSafeButton.setText("Create new Safe Account", .bordered)
        demoButton.setText("Try Demo", .plain)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let event = trackingEvent {
            Tracker.trackEvent(event)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // center the text relative to the window instead of containing view
        // because this screen is used several times in different tabs
        // and the Y position of this view will be different -> leading to
        // the visual jumps when switching the tabs.
        if let window = view.window, buttonYConstraint == nil || buttonYConstraint?.isActive == false {
            buttonYConstraint = descriptionLabel.centerYAnchor.constraint(equalTo: window.centerYAnchor)
            buttonYConstraint?.isActive = true
            view.setNeedsLayout()
        }
    }

    @IBAction private func didTapLoadSafe(_ sender: Any) {
        let selectNetworkVC = SelectNetworkViewController()
        selectNetworkVC.screenTitle = "Load Safe Account"
        selectNetworkVC.descriptionText = "Select network on which your Safe Account was created:"
        selectNetworkVC.completion = { [unowned selectNetworkVC] chain  in
            let vc = EnterSafeAddressViewController()
            vc.chain = chain
            let ribbon = RibbonViewController(rootViewController: vc)
            ribbon.chain = vc.chain
            vc.completion = {
                selectNetworkVC.dismiss(animated: true, completion: nil)
            }
            selectNetworkVC.show(ribbon, sender: selectNetworkVC)
        }
        let vc = ViewControllerFactory.modal(viewController: selectNetworkVC)
        present(vc, animated: true)
    }

    @IBAction func didTapCreateSafe(_ sender: Any) {
        createSafeFlow = CreateSafeFlow(completion: { [weak self] _ in
            self?.createSafeFlow = nil
        })
        present(flow: createSafeFlow, dismissableOnSwipe: false)
    }

    @IBAction func didTapTryDemo(_ sender: Any) {
        let chain = Chain.mainnetChain()
        
        let demoAddress: Address = Address(exactly: Safe.demoAddress)
        let demoName = "Demo Safe"
        let safeVersion = "1.1.1"
        Safe.create(address: demoAddress.checksummed, version: safeVersion, name: demoName, chain: chain)
        
        App.shared.notificationHandler.safeAdded(address: demoAddress)
        Tracker.trackEvent(.tryDemo)
    }
}
