//
//  FirebaseRemoteConfig.swift
//  Multisig
//
//  Created by Moaaz on 4/15/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Firebase

class FirebaseRemoteConfig {
    static let shared = FirebaseRemoteConfig()
    enum Key: String {
        case newestVersion
        case deprecatedSoon
        case deprecated
    }

    private var remoteConfig: RemoteConfig!
    private let defaultValues: [String : NSObject] = [Key.newestVersion.rawValue : App.configuration.app.marketingVersion as NSObject,
                                                      Key.deprecatedSoon.rawValue : "" as NSObject,
                                                      Key.deprecated.rawValue : "" as NSObject]
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(defaultValues)
    }

    func value<T>(key: Key) -> T? {
        remoteConfig.configValue(forKey: key.rawValue) as? T
    }
}
