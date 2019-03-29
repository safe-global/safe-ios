//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Mock file manager used for testing purposes
class MockFileManager: FileManager {

    func appSupportURL() throws -> URL {
        return try url(for: .applicationSupportDirectory,
                       in: .userDomainMask,
                       appropriateFor: nil,
                       create: false)
    }

    var notExistingURLs = [URL]()
    var existingURLs = [URL]()

    override func fileExists(atPath path: String) -> Bool {
        if existingURLs.contains(where: { $0.path == path }) { return true }
        if notExistingURLs.contains(where: { $0.path == path }) { return false }
        return super.fileExists(atPath: path)
    }

    override func removeItem(at URL: URL) throws {
        if let index = existingURLs.firstIndex(of: URL) {
            existingURLs.remove(at: index)
            if !super.fileExists(atPath: URL.path) {
                return
            }
        }
        try super.removeItem(at: URL)
    }

}
