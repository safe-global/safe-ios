//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Ethereum

/// Responsible for data conversion back-and-forth between WebConnection-related objects and the WalletConnectSwift's library objects.
class WebConnectionToSessionTransformer {

    func update(connection: WebConnection, with session: Session) {
        guard let myself = connection.localPeer, let other = connection.remotePeer else {
            assertionFailure("Local or remote peer are not set")
            return
        }
        if myself.role == .wallet && other.role == .dapp {
            // if dapp didn't suggest chain id, pick mainnet by default
            connection.chainId = session.dAppInfo.chainId ?? Int(Chain.ChainID.ethereumMainnet)!
            other.peerId = session.dAppInfo.peerId
            update(peer: other, with: session.dAppInfo.peerMeta)
        } else if myself.role == .dapp && other.role == .wallet, let walletInfo = session.walletInfo {
            connection.accounts = walletInfo.accounts.compactMap(Address.init)
            connection.chainId = walletInfo.chainId
            other.peerId = walletInfo.peerId
            update(peer: other, with: walletInfo.peerMeta)
        }
    }

    private func update(peer: WebConnectionPeerInfo, with peerMeta: Session.ClientMeta) {
        peer.url = peerMeta.url
        peer.name = peerMeta.name
        peer.description = peerMeta.description
        peer.icons = peerMeta.icons
        peer.deeplinkScheme = peerMeta.scheme
    }

    func session(from connection: WebConnection) -> Session? {
        guard let myself = connection.localPeer,
              let remotePeer = connection.remotePeer
        else {
            return nil
        }
        if myself.role == .wallet && remotePeer.role == .dapp {
            let dappInfo: Session.DAppInfo = dappInfo(from: remotePeer)
            let walletInfo: Session.WalletInfo = walletInfo(from: myself, connection: connection)
            let result = Session(
                url: connection.connectionURL.wcURL,
                dAppInfo: dappInfo,
                walletInfo: walletInfo
            )
            return result
        } else if myself.role == .dapp && remotePeer.role == .wallet {
            let dappInfo = self.dappInfo(from: myself)
            let walletInfo = self.walletInfo(from: remotePeer, connection: connection)
            let result = Session(
                url: connection.connectionURL.wcURL,
                dAppInfo: dappInfo,
                walletInfo: walletInfo
            )
            return result
        } else {
            return nil
        }
    }

    private func walletInfo(from peer: WebConnectionPeerInfo, connection: WebConnection) -> Session.WalletInfo {
        let peerMeta = clientMeta(from: peer)
        let result = Session.WalletInfo(
                approved: connection.status == .approved || connection.status == .opened,
                accounts: connection.accounts.map(\.checksummed),
                chainId: connection.chainId ?? 0,
                peerId: peer.peerId,
                peerMeta: peerMeta
        )
        return result
    }

    private func dappInfo(from peer: WebConnectionPeerInfo) -> Session.DAppInfo {
        let peerMeta = clientMeta(from: peer)
        let result = Session.DAppInfo(
            peerId: peer.peerId,
            peerMeta: peerMeta,
            chainId: nil,
            approved: true
        )
        return result
    }

    private func clientMeta(from peer: WebConnectionPeerInfo) -> Session.ClientMeta {
        let peerMeta = Session.ClientMeta(
                name: peer.name,
                description: peer.description,
                icons: peer.icons,
                url: peer.url,
                scheme: peer.deeplinkScheme
        )
        return peerMeta
    }

    func requestId(id: RequestID?) -> WebConnectionRequestId? {
        switch id {
        case let value as String:
            return WebConnectionRequestId(stringValue: value)
        case let value as Int:
            return WebConnectionRequestId(intValue: value)
        case let value as Double:
            return WebConnectionRequestId(doubleValue: value)
        case .none:
            return nil
        default:
            return nil
        }
    }

    func requestId(id: WebConnectionRequestId) -> RequestID? {
        if let int = id.intValue {
            return int
        } else if let double = id.doubleValue {
            return double
        } else if let string = id.stringValue {
            return string
        } else {
            return nil
        }
    }

    fileprivate func openConnectionRequest(_ request: Request) -> WebConnectionOpenRequest {
        let result = WebConnectionOpenRequest(
            id: requestId(id: request.id),
            method: request.method,
            error: nil,
            json: request.jsonString,
            status: .initial,
            connectionURL: WebConnectionURL(wcURL: request.url),
            createdDate: nil
        )
        return result
    }

    fileprivate func signatureRequest(_ request: Request) -> WebConnectionSignatureRequest? {
        guard request.parameterCount == 2 else { return nil }

        do {
            let address = try request.parameter(of: AddressString.self, at: 0).address
            let message = try request.parameter(of: DataString.self, at: 1).data
            let result = WebConnectionSignatureRequest(
                id: requestId(id: request.id),
                method: request.method,
                error: nil,
                json: request.jsonString,
                status: .initial,
                connectionURL: WebConnectionURL(wcURL: request.url),
                createdDate: nil,
                account: address,
                message: message
            )
            return result
        } catch {
            LogService.shared.error("Failed to create an eth_sign request parameters: \(error)")
            return nil
        }
    }

    fileprivate func sendTransactionRequest(_ request: Request) -> WebConnectionSendTransactionRequest? {
        do {
            guard request.parameterCount == 1 else { return nil }

            let rpcTx = try request.parameter(of: EthRpc1.eth_sendTransaction.Transaction.self, at: 0)
            let transaction = rpcTx.ethTransaction
            
            let result = WebConnectionSendTransactionRequest(
                id: requestId(id: request.id),
                method: request.method,
                error: nil,
                json: request.jsonString,
                status: .initial,
                connectionURL: WebConnectionURL(wcURL: request.url),
                createdDate: nil,
                transaction: transaction
            )
            return result
        } catch {
            LogService.shared.error("Failed to create an eth_sendTransaction request parameters: \(error)")
            return nil
        }
    }

    fileprivate func genericRequest(_ request: Request) -> WebConnectionRequest {
        let result = WebConnectionRequest(
            id: requestId(id: request.id),
            method: request.method,
            error: nil,
            json: request.jsonString,
            status: .initial,
            connectionURL: WebConnectionURL(wcURL: request.url),
            createdDate: nil
        )
        return result
    }

    func request(from request: Request) -> WebConnectionRequest? {
        switch request.method {
        case "wc_sessionRequest":
            return openConnectionRequest(request)

        case "eth_sign":
            return signatureRequest(request)

        case "eth_sendTransaction":
            return sendTransactionRequest(request)

        default:
            return genericRequest(request)
        }
    }
}
