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
        case safeClaimEnabled
        case crashDebugEnabled
    }

    private var remoteConfig: RemoteConfig
    private let defaultValues: [String : NSObject] = [Key.newestVersion.rawValue : "" as NSObject,
                                                      Key.deprecatedSoon.rawValue : "" as NSObject,
                                                      Key.deprecated.rawValue : "" as NSObject,
                                                      Key.safeClaimEnabled.rawValue : false as NSObject]
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        // we have this codition to make it faster to test on staging
        if App.configuration.services.environment != .production {
            settings.minimumFetchInterval = 0
        }
        remoteConfig.setDefaults(defaultValues)
        fetchConfig()
    }

    func boolValue(key: Key) -> Bool? {
        remoteConfig[key.rawValue].boolValue
    }

    func value(key: Key) -> String? {
        remoteConfig[key.rawValue].stringValue
    }

    func fetchConfig() {
        remoteConfig.fetchAndActivate { status, error in
            if [RemoteConfigFetchAndActivateStatus.successFetchedFromRemote, .successUsingPreFetchedData].contains(status) {
                LogService.shared.info("Config fetched!")
            } else {
                LogService.shared.info("Error: \(error?.localizedDescription ?? "Config not fetched")")
            }
        }
    }
}
