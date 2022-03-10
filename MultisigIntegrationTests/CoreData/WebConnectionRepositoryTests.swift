//
// Created by Dmitry Bespalov on 11.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
@testable import Multisig
import XCTest
import WalletConnectSwift

class WebConnectionRepositoryTests: CoreDataTestCase {
    func testSavesPeers() throws {
        let controller = WebConnectionController()
        let url = WebConnectionURL(wcURL: WCURL(topic: UUID().uuidString, version: "1", bridgeURL: URL(string: "https://example.org")!, key: UUID().uuidString))
        let connection = controller.createConnection(from: url)
        XCTAssertNotNil(connection.localPeer)
        XCTAssertNotNil(connection.remotePeer)

        let peerInfo = connection.remotePeer as? GnosisSafeWebPeerInfo
        XCTAssertNotNil(peerInfo)
        controller.save(connection)

        let fetchedConnection = controller.connection(for: url)
        XCTAssertNotNil(fetchedConnection)
        XCTAssertNotNil(fetchedConnection?.localPeer)
        XCTAssertNotNil(fetchedConnection?.remotePeer)

        let fetchedPeerInfo = fetchedConnection?.remotePeer as? GnosisSafeWebPeerInfo
        XCTAssertNotNil(fetchedPeerInfo)
    }

    func testSavesRequest() throws {
        let controller = WebConnectionController()
        let url = WebConnectionURL(wcURL: WCURL(topic: UUID().uuidString, version: "1", bridgeURL: URL(string: "https://example.org")!, key: UUID().uuidString))
        let id = WebConnectionRequestId(intValue: 1645101302900668)
        let json = """
        {"id":1645101302900668,"jsonrpc":"2.0","method":"eth_sign","params":["0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0","0xec6a7b6c1a89"]}
        """
        let request = WebConnectionRequest(id: id, method: "eth_sign", error: nil, json: json, status: .pending, connectionURL: url, createdDate: Date())
        let connection = controller.createConnection(from: url)
        controller.save(connection)

        controller.save(request)

        let fetchedRequest = controller.request(url, id)

        XCTAssertNotNil(fetchedRequest)
        XCTAssertTrue(fetchedRequest is WebConnectionSignatureRequest)
        XCTAssertEqual(fetchedRequest?.status, .pending)

        guard let signRequest = fetchedRequest as? WebConnectionSignatureRequest else { return }

        XCTAssertEqual(signRequest.account, "0x728cafe9fB8CC2218Fb12a9A2D9335193caa07e0")
        XCTAssertEqual(signRequest.message, Data(hex: "0xec6a7b6c1a89"))
    }
}
