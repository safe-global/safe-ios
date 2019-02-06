//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation


private class BundleMarker {}

extension Bundle {
    static let thisBundle: Bundle = {
        let value = Bundle(for: BundleMarker.self)
        guard let resourcesURL = value.url(forResource: "ReplaceBrowserExtensionFacadeResources",
                                           withExtension: "bundle") else { return value }
        return Bundle(path: resourcesURL.path) ?? value
    }()
}

func LocalizedString(_ key: String, comment: String) -> String {
    return NSLocalizedString(key, bundle: Bundle.thisBundle, comment: comment)
}
