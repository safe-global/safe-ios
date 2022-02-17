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
}