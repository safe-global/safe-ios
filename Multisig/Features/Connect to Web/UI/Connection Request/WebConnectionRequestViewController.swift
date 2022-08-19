//
//  WebConnectionRequestViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionRequestViewController: WebConnectionContainerViewController, WebConnectionObserver {
    var chooseOwnerKeyVC: ChooseOwnerKeyViewController!

    var selectedKey: KeyInfo? {
        chooseOwnerKeyVC?.selectedKey
    }

    var connectionController: WebConnectionController!
    var connection: WebConnection!
    var chain: Chain!

    enum State {
        case initial
        case loading
        case active
        case connecting
        case connected
        case failed
    }

    private var state: State = .initial

    convenience init() {
        self.init(namedClass: WebConnectionContainerViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connection requested"

        assert(connection != nil)
        assert(connectionController != nil)

        // update with current connection state before observing.
        didUpdate(connection: connection)

        connectionController.attach(observer: self, to: connection)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.webConnectionConnectionRequest)
    }

    func didUpdate(connection: WebConnection) {
        assert(Thread.isMainThread)
        self.connection = connection

        switch connection.status {
        case .initial, .handshaking:
            updateState(.loading)

        case .approving:
            updateState(.active)

        case .approved:
            updateState(.connecting)

        case .opened:
            updateState(.connected)
            finish()

        case .final:
            if connection.lastError != nil {
                updateState(.failed)
            }
            finish()

        default:
            // not interested in other states
            break
        }
    }

    func updateState(_ newState: State) {
        assert(Thread.isMainThread)
        guard state != newState else { return }

        state = newState

        switch state {
        case .initial:
            // do nothing here
            break

        case .loading:
            headerView.isHidden = true
            activityIndicator.startAnimating()
            actionPanelView.setEnabled(false)

        case .active:
            chain = Chain.by(String(connection.chainId!))!
            ribbonView.update(chain: chain)
            contentView.isUserInteractionEnabled = true
            activityIndicator.stopAnimating()
            actionPanelView.setEnabled(true)
            showKeyPicker()

        case .connecting:
            contentView.isUserInteractionEnabled = false
            activityIndicator.startAnimating()
            actionPanelView.setEnabled(false)

        case .connected:
            App.shared.snackbar.show(message: "Connected to Safe.", icon: .success)

        case .failed:
            let message = ["Failed to connect.", (connection.lastError ?? "")].joined(separator: " ")
            App.shared.snackbar.show(message: message)
        }
    }

    func showKeyPicker() {
        guard let remotePeer = connection.remotePeer else {
            assertionFailure("Expected to have the remote app data")
            return
        }
        headerView.imageView.setImage(
            url: remotePeer.icons.first,
            placeholder: UIImage(named: "connection-placeholder"),
            failedImage: UIImage(named: "connection-placeholder"))
        headerView.textLabel.text = "\(remotePeer.name.prefix(75)) requests to connect to your key"
        headerView.detailTextLabel.text = remotePeer.url.host
        headerView.isHidden = false

        let keys = connectionController.accountKeys()
        chooseOwnerKeyVC = ChooseOwnerKeyViewController(
                owners: keys,
                chainID: String(connection.chainId!),
                header: .none,
                requestsPasscode: false,
                selectedKey: keys.first,
                balancesLoader: nil,
                completionHandler: nil)
        chooseOwnerKeyVC.completionHandler = { [weak chooseOwnerKeyVC] _ in
            chooseOwnerKeyVC?.reload()
        }
        viewControllers = [chooseOwnerKeyVC]
        displayChild(at: 0, in: contentView)
    }

    override func didCancel() {
        connectionController.userDidCancel(connection)
    }

    override func didReject() {
        connectionController.userDidReject(connection)
        Tracker.trackEvent(.webConnectionConnectionRequestRejected)
    }

    override func didConfirm() {
        assert(selectedKey != nil)
        connection.accounts = [selectedKey!.address]
        connectionController.userDidApprove(connection)
        Tracker.trackEvent(.webConnectionConnectionRequestConfirmed,
                           parameters: TrackingEvent.keyTypeParameters(selectedKey!))
    }

    private func finish() {
        connectionController.detach(observer: self)
        onFinish()
    }
}
