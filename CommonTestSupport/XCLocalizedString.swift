//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

private final class BundleMarker {}

private let XCBundle = localizationBundle()

/// Fetches localized string in the test bundle
///
/// - Parameter key: localization key
/// - Returns: localized string
public func XCLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, bundle: XCBundle, comment: "")
}

/// Fetches localized string from the table in the test bundle
///
/// - Parameters:
///   - key: localization key
///   - table: localization table (by convention it should be the name of the target framework, imported
///     to the app you are testing).
/// - Returns: localized key
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

/// Blocks caller on the current thread for the `delay` time period
///
/// - Parameter delay: period to block.
public func delay(_ delay: TimeInterval = 0.1) {
    if delay == 0 { return }
    RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
}
