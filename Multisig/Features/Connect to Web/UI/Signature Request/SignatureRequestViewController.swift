//
//  WCIncomingKeyRequestViewController.swift
//  WCIncomingKeyRequestViewController
//
//  Created by Andrey Scherbovich on 13.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import BigInt
import WalletConnectSwift

class SignatureRequestViewController: WebConnectionContainerViewController, WebConnectionRequestObserver, PasscodeProtecting {

    var contentVC: SignatureRequestContentViewController!
    var controller: WebConnectionController!
    var connection: WebConnection!
    var request: WebConnectionSignatureRequest!

    private var balanceLoadingTask: URLSessionTask?
    internal var chain: Chain?
    internal var keyInfo: KeyInfo?
    internal var keystoneSignFlow: KeystoneSignFlow!
    
    convenience init() {
        self.init(namedClass: WebConnectionContainerViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Signature request"

        contentVC = SignatureRequestContentViewController()
        viewControllers = [contentVC]
        displayChild(at: 0, in: contentView)

        connection = controller.connection(for: request)

        if let chain = controller.chain(for: request),
            let account = connection.accounts.first,
            let keyInfo = (try? KeyInfo.firstKey(address: account)) {
            self.chain = chain
            self.keyInfo = keyInfo
        }

        if let peer = connection.remotePeer {
            headerView.textLabel.text = peer.name
            headerView.detailTextLabel.text = peer.url.host
            let placeholder = UIImage(named: "connection-placeholder")
            headerView.imageView.setImage(url: peer.icons.first, placeholder: placeholder, failedImage: placeholder)
        } else {
            headerView.isHidden = true
        }

        contentVC.detailsLabel.text = request.message.toHexStringWithPrefix()
        contentVC.signerAddressView.setContent(loadingView())
        contentVC.signerAddressView.setTitle("Sign with")

        ribbonView.update(chain: chain)
        actionPanelView.setConfirmText("Submit")

        loadAccountBalance()

        controller.attach(observer: self, to: request)
    }

    deinit {
        controller.detach(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.webConnectionSignRequest)
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // needed to react to the "swipe down" to close the modal screen
        parent?.presentationController?.delegate = self
    }

    // MARK: - Events

    override func didCancel() {
        didReject()
    }

    override func didReject() {
        reject()
    }

    override func didConfirm() {
        authorizeAndSign()
    }

    func didUpdate(request: WebConnectionRequest) {
        if request.status == .success || request.status == .failed {
            onFinish()
        }
    }

    // MARK: - Loading Balance

    func loadAccountBalance() {
        guard let keyInfo = keyInfo, let chain = chain else {
            return
        }

        let balanceLoader = DefaultAccountBalanceLoader(chain: chain)

        balanceLoadingTask?.cancel()
        balanceLoadingTask = balanceLoader.loadBalances(for: [keyInfo]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                // if request cancelled, do nothing, don't call completion.
                if (error as NSError).code == URLError.cancelled.rawValue &&
                    (error as NSError).domain == NSURLErrorDomain {
                    return
                }

                self.display(balance: AccountBalanceUIModel(displayAmount: "", isEnabled: true))

            case .success(let balances):
                guard let balance = balances.first else {
                    self.display(balance: AccountBalanceUIModel(displayAmount: "", isEnabled: true))
                    return
                }
                self.display(balance: balance)
            }
        }
    }

    private func display(balance: AccountBalanceUIModel) {
        guard let chain = chain, let keyInfo = keyInfo else {
            return
        }
        let uiInfo = NamingPolicy.name(for: keyInfo.address, chainId: chain.id!)

        let content = MiniAccountAndBalancePiece()
        let model = MiniAccountInfoUIModel(
            prefix: chain.shortName,
            address: keyInfo.address,
            label: uiInfo.name,
            imageUri: uiInfo.imageUri,
            badge: keyInfo.keyType.imageName,
            balance: balance.displayAmount
        )

        content.setModel(model)
        contentVC.signerAddressView.setContent(content)
    }

    func loadingView() -> UIView {
        let skeleton = UILabel()
        skeleton.textAlignment = .right
        skeleton.isSkeletonable = true
        skeleton.skeletonTextLineHeight = .fixed(25)
        skeleton.showSkeleton(delay: 0.2)
        return skeleton
    }

    // MARK: - Signing

    private func authorizeAndSign() {
        authenticate(options: [.useForConfirmation]) { [weak self] success, _ in
            if success {
                self?.sign()
            }
        }
    }

    let signer = WalletSigner()

    // Sign calculates an Ethereum ECDSA signature for:
    // keccack256("\x19Ethereum Signed Message:\n" + len(message) + message))
    private func sign() {
        signer.signWCSignReq(controller: self)
    }

    internal func confirm(signature: Data, trackingParameters: [String: Any]? = nil) {
        let trackingParameters: [String: Any] = ["source": "ctw"]
        if let keyInfo = keyInfo {
            Tracker.trackEvent(.userTransactionConfirmed,
                               parameters: TrackingEvent.keyTypeParameters(keyInfo, parameters: trackingParameters))
        }
        controller.respond(request: request, with: WebConnectionSignatureRequest.response(signature: signature))
    }

    private func reject() {
        Tracker.trackEvent(.webConnectionSignRequestRejected)
        controller.respond(request: request, errorCode: WebConnectionRequest.ErrorCode.requestRejected.rawValue, message: "User rejected the request")
    }
}

extension SignatureRequestViewController: WCSignReqSource {

}
