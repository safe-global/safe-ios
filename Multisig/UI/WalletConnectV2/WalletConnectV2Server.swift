//
//  WalletConnectV2Server.swift
//  Multisig
//
//  Created by Mouaz on 2/21/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectPairing
import WalletConnectSign
import WalletConnectUtils
import WalletConnectPairing
import WalletConnectRouter
import Web3
import CryptoSwift
import Combine

class WalletConnectV2Server {
    var sessionItems: [ActiveSessionItem] = []

    var currentProposal: Session.Proposal?
    private var publishers = [AnyCancellable]()

    var onClientConnected: (() -> Void)?

    func canConnect(url: String) -> Bool {
        WalletConnectURI(string: url) != nil
    }

    func pairClient(uri: WalletConnectURI) {
        Task {
            do {
                try await Pair.instance.pair(uri: uri)
            } catch {
                print("[DAPP] Pairing connect error: \(error)")
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
}

extension WalletConnectV2Server {

    func didApproveSession() {
        let proposal = currentProposal!
        currentProposal = nil
        var sessionNamespaces = [String: SessionNamespace]()
        proposal.requiredNamespaces.forEach {
            let caip2Namespace = $0.key
            let proposalNamespace = $0.value
            let accounts = Set(proposalNamespace.chains!.compactMap { Account($0.absoluteString + ":\(self.accounts[$0.namespace]!)") })

            let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
            sessionNamespaces[caip2Namespace] = sessionNamespace
        }
        approve(proposalId: proposal.id, namespaces: sessionNamespaces)
    }

    func didRejectSession() {
        let proposal = currentProposal!
        currentProposal = nil
        reject(proposalId: proposal.id, reason: .userRejectedChains)
    }
}

extension WalletConnectV2Server {
    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    print("Client connected")
                    self?.onClientConnected?()
                }
            }.store(in: &publishers)

        // TODO: Adapt proposal data to be used on the view
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionProposal in
                print("[RESPONDER] WC: Did receive session proposal")
                self?.currentProposal = sessionProposal
                    self?.showSessionProposal(Proposal(proposal: sessionProposal)) // FIXME: Remove mock
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionRequest in
                print("[RESPONDER] WC: Did receive session request")
                self?.showSessionRequest(sessionRequest)
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigationController?.popToRootViewController(animated: true)
            }.store(in: &publishers)

        Sign.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                self?.reloadSessions(sessions)
            }.store(in: &publishers)
    }

    private func getActiveSessionItem(for settledSessions: [Session]) -> [ActiveSessionItem] {
        return settledSessions.map { session -> ActiveSessionItem in
            let app = session.peer
            return ActiveSessionItem(
                dappName: app.name ,
                dappURL: app.url ,
                iconURL: app.icons.first ?? "",
                topic: session.topic)
        }
    }

    private func reloadSessions(_ sessions: [Session]) {
        sessionItems = getActiveSessionItem(for: sessions)
        walletView.tableView.reloadData()
    }
}

