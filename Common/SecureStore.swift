//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol SecureStore {

    func save(data: Data, forKey: String) throws
    func data(forKey: String) throws -> Data?
    func removeData(forKey: String) throws
    func destroy() throws

}
