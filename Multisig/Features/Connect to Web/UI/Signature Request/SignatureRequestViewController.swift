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

class SignatureRequestViewController: WebConnectionContainerViewController, WebConnectionRequestObserver {

    var contentVC: SignatureRequestContentViewController!
    var controller: WebConnectionController!
    var connection: WebConnection!
    var request: WebConnectionSignatureRequest!

    private var balanceLoadingTask: URLSessionTask?
    private var chain: Chain?
    private var keyInfo: KeyInfo?

    private var wcConnector: WCWalletConnectionController!

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
        if App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForConfirmation) {
            let passcodeVC = EnterPasscodeViewController()
            passcodeVC.passcodeCompletion = { [weak self] success in
                self?.dismiss(animated: true, completion: {
                    if success {
                        self?.sign()
                    }
                })
            }
            passcodeVC.modalPresentationStyle = .fullScreen
            present(passcodeVC, animated: true)
        } else {
            sign()
        }
    }

    // Sign calculates an Ethereum ECDSA signature for:
    // keccack256("\x19Ethereum Signed Message:\n" + len(message) + message))
    private func sign() {
        guard let keyInfo = keyInfo else {
            return
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                guard let pk = try keyInfo.privateKey() else {
                    App.shared.snackbar.show(message: "Private key not available")
                    return
                }
                let preimage = "\u{19}Ethereum Signed Message:\n\(request.message.count)".data(using: .utf8)! + request.message
                let signatureParts = try pk._store.sign(message: preimage.bytes)
                let signature = Data(signatureParts.r) + Data(signatureParts.s) + Data([UInt8(signatureParts.v)])
                confirm(signature:  signature)
            } catch {
                App.shared.snackbar.show(message: "Failed to sign: \(error.localizedDescription)")
            }

        case .walletConnect:
            wcConnector = WCWalletConnectionController()
            wcConnector.connect(keyInfo: keyInfo, from: self) { [weak self] success in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                    guard let self = self else { return }

                    defer { self.wcConnector = nil }

                    guard success else {
                        return
                    }

                    let hexMessage = self.request.message.toHexStringWithPrefix()

                    let wcVC = WCPendingConfirmationViewController(
                        hexMessage,
                        keyInfo: keyInfo,
                        title: "Sign Message"
                    )

                    wcVC.sign { [weak self] hexSignature in
                        guard let self = self else { return }
                        assert(Thread.isMainThread)
                        let signature = Data(hex: hexSignature)
                        self.confirm(signature: signature)
                    }

                    self.present(wcVC, animated: true)
                }
            }

        case .ledgerNanoX:
            let hexToSign = request.message.toHexStringWithPrefix()

            let request = SignRequest(title: "Sign Message",
                                      tracking: ["action": "signMessage"],
                                      signer: keyInfo,
                                      hexToSign: hexToSign)

            let ledgerSignerVC = LedgerSignerViewController(request: request)

            present(ledgerSignerVC, animated: true)

            ledgerSignerVC.completion = { [weak self] hexSignature in
                // subtracting 4 from the v component of the signature in order to convert it to the ethereum signature
                var signature = Data(hex: hexSignature)
                assert(signature.count == 65)
                signature[64] -= 4
                self?.confirm(signature: signature)
            }
        }
    }

    private func confirm(signature: Data) {
        if let keyInfo = keyInfo {
            Tracker.trackEvent(.webConnectionSignRequestConfirmed,
                               parameters: TrackingEvent.keyTypeParameters(keyInfo))
        }
        controller.respond(request: request, with: WebConnectionSignatureRequest.response(signature: signature))
    }

    private func reject() {
        Tracker.trackEvent(.webConnectionSignRequestRejected)
        controller.respond(request: request, errorCode: WebConnectionRequest.ErrorCode.requestRejected.rawValue, message: "User rejected the request")
    }
}