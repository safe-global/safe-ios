//
//  WebConnectionRequestViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionRequestViewController: ContainerViewController, UIAdaptivePresentationControllerDelegate, WebConnectionObserver, ActionPanelViewDelegate {
    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var actionPanelView: ActionPanelView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var closeButton: UIBarButtonItem!
    var chooseOwnerKeyVC: ChooseOwnerKeyViewController!

    var selectedKey: KeyInfo? {
        chooseOwnerKeyVC?.selectedKey
    }

    var connectionController: WebConnectionController!
    var connection: WebConnection!
    var chain: Chain!

    var onFinish: () -> Void = { }

    enum State {
        case initial
        case loading
        case active
        case connecting
        case connected
        case failed
    }

    private var state: State = .initial

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connection requested"

        assert(connection != nil)
        assert(connectionController != nil)

        closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        navigationItem.leftBarButtonItem = closeButton

        activityIndicator.transform = CGAffineTransform(scaleX: 2, y: 2)

        actionPanelView.delegate = self

        // update with current connection state before observing.
        didUpdate(connection: connection)

        connectionController.attach(observer: self, to: connection)
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
            App.shared.snackbar.show(message: "Connected to Gnosis Safe.", icon: .success)

        case .failed:
            let message = ["Failed to connect.", (connection.lastError ?? "")].joined(separator: " ")
            App.shared.snackbar.show(message: message)
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // needed to react to the "swipe down" to close the modal screen
        parent?.presentationController?.delegate = self
    }

    func showKeyPicker() {
        guard let remotePeer = connection.remotePeer else {
            assertionFailure("Expected to have the remote app data")
            return
        }
        let keys = connectionController.accountKeys()
        chooseOwnerKeyVC = ChooseOwnerKeyViewController(
                owners: keys,
                chainID: String(connection.chainId!),
                header: .detail(
                    imageUri: remotePeer.icons.first,
                    placeholder: UIImage(named: "connection-placeholder"),
                    title: "\(remotePeer.name.prefix(75)) requests to connect to your key",
                    detail: remotePeer.url.absoluteString),
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

    @objc func didTapCloseButton() {
        connectionController.userDidCancel(connection)
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        connectionController.userDidCancel(connection)
    }

    func didReject() {
        connectionController.userDidReject(connection)
    }

    func didConfirm() {
        assert(selectedKey != nil)
        connection.accounts = [selectedKey!.address]
        connectionController.userDidApprove(connection)
    }

    private func finish() {
        connectionController.detach(observer: self)
        onFinish()
    }
}
