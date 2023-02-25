//
//  WalletConnectV2Manager.swift
//  Multisig
//
//  Created by Mouaz on 2/22/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectNetworking
import WalletConnectPairing
import Combine
import WalletConnectSign
import WalletConnectUtils
import WalletConnectRouter
import Web3
class WalletConnectManager {
    static let shared = WalletConnectManager()
    
    private var publishers = [AnyCancellable]()
    
    private init() { }

    func config() {
        Networking.configure(projectId: App.configuration.walletConnect.walletConnectProjectId,
                             socketFactory: SocketFactory())

        let metadata = AppMetadata(
            name: Bundle.main.displayName,
            description: "The most trusted platform to manage digital assets on Ethereum",
            url: App.configuration.services.webAppURL.absoluteString,
            icons: ["https://app.safe.global/favicons/mstile-150x150.png",
                     "https://app.safe.global/favicons/logo_120x120.png"])

        Pair.configure(metadata: metadata)
        setUpAuthSubscribing()
    }

    func canConnect(url: String) -> Bool {
        WalletConnectURI(string: url) != nil
    }

    func pairClient(url: String) {
        guard let uri = WalletConnectURI(string: url) else { return }
        pairClient(uri: uri)
    }

    func pairClient(uri: WalletConnectURI) {
        Task {
            do {
                try await Pair.instance.pair(uri: uri)
            } catch {
                print(error)
                LogService.shared.error("DAPP: Failed to register to remote notifications \(error)")
            }
        }
    }

    private func respondOnSign(request: Request, response: AnyCodable) {
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(response))
            } catch {
                print("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }

    func respondOnReject(request: Request) {
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .error(.init(code: 0, message: ""))
                )
            } catch {
                print("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }

    func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                print("[DAPP] Approve Session error: \(error)")
            }
        }
    }

    func reject(proposalId: String, reason: RejectionReason) {
        Task {
            do {
                try await Sign.instance.reject(proposalId: proposalId, reason: reason)
            } catch {
                print("[DAPP] Reject Session error: \(error)")
            }
        }
    }
    
    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    print("Client connected")
                    // TODO: Handle connection success
                }
            }.store(in: &publishers)

        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                self?.approveSession(proposal: sessionProposal)
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                // TODO: Handle incomming request
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // TODO: Handle session disconnected
            }.store(in: &publishers)

        Sign.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                // TODO: Handle session 
            }.store(in: &publishers)
    }

    func approveSession(proposal: Session.Proposal) {
        guard let safe = try? Safe.getSelected() else { return }
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(safe.addressValue)") })

            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }
}

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Safe Multisig"
    }
}

