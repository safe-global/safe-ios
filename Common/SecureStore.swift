//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// `SecureStore` defines a protocol of a secure, encrypted store of arbitrary Data referenced by String keys.
public protocol SecureStore {

    /// Saves the `data` by `forKey` key. If the key is already in use, this method throws error.
    ///
    /// - Parameters:
    ///   - data: The data for secure storage
    ///   - forKey: Key to store the data
    /// - Throws: Throws error if the key is already used or some underlying error occurred.
    func save(data: Data, forKey: String) throws
    /// Returns data stored by the key or nil in case it was not found.
    ///
    /// - Parameter forKey: Key of the data stored.
    /// - Returns: Data or nil, if it was not found.
    /// - Throws: This method could throw if there was a problem in the secure store.
    func data(forKey: String) throws -> Data?
    /// Removes stored data by key. If there's no data assigned to the key, the method is harmless.
    ///
    /// - Parameter forKey: Key of the stored data
    /// - Throws: May throw error if there was a problem with the secure store.
    func removeData(forKey: String) throws
    /// Deletes all the data previously stored in the secure store.
    ///
    /// - Throws: May throw error if there was a problem with the secure store.
    func destroy() throws

}
