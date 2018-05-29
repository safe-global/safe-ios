//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

private final class BundleMarker {}

private let XCBundle = localizationBundle()

public func XCLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, bundle: XCBundle, comment: "")
}

public func XCLocalizedString(_ key: String, table: String) -> String {
    return NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleMarker.self), value: key, comment: "")
}

private func localizationBundle() -> Bundle {
    let testBundle = Bundle(for: BundleMarker.self)
    let localizedBundle: Bundle
    if let path = testBundle.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) {
        localizedBundle = bundle
    } else {
        localizedBundle = testBundle
    }
    return localizedBundle
}

public func delay(_ delay: TimeInterval = 0.1) {
    if delay == 0 { return }
    RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
}
