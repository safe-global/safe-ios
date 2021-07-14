//
//  XCTestCase.swift
//  MultisigIntegrationTests
//
//  Created by Dmitry Bespalov on 14.07.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import XCTest

// Presenting view controller or a view
extension XCTestCase {
    func createWindow(_ controller: UIViewController) {
        guard let window = UIApplication.shared.windows.first else {
            XCTFail("Must have active window")
            return
        }
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController?.present(controller, animated: false)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(controller.view.window)
    }

    func addToWindow(_ view: UIView) {
        guard let window = UIApplication.shared.windows.first else {
            XCTFail("Must have active window")
            return
        }
        window.addSubview(view)
    }
}

// JSON from file
extension XCTestCase {
    func json<T: Decodable>(_ filename: String) throws -> T {
        let file = Bundle(for: Self.self).url(forResource: filename, withExtension: nil)!
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        let result = try decoder.decode(T.self, from: data)
        return result
    }
}
