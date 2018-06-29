//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct BrowserExtensionFixture {

    public static let testJSON = """
            {"expirationDate": "2018-05-09T14:18:55+00:00",
              "signature": {
                "v": 27,
                "r":"test",
                "s":"me"
              }
            }
            """

}

public struct PairingRequestFixture {

    public static let testJSON = """
            {
                "temporaryAuthorization": {
                    "expirationDate": "2018-05-09T14:18:55+00:00",
                    "signature": {
                        "v": 27,
                        "r":"test",
                        "s":"me"
                    }
                },
                "signature": {
                    "v" : 35,
                    "r" : "test",
                    "s" : "it"
                }
            }
            """

}
