//
//  AppUpdateManager.swift
//  Multisig
//
//  Created by Moaaz on 4/16/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class UpdateController {
    func appUpdateStatus() -> UpdateAppViewController? {
        let remoteConfig = FirebaseRemoteConfig.shared
        let appVersion = App.configuration.app.marketingVersion

        let latestAppVersion: String? = remoteConfig.value(key: .newestVersion)

        if appVersion == latestAppVersion { return nil }
        let deprecatedVersions: String? = remoteConfig.value(key: .deprecated)
        var style = UpdateAppViewController.Style.optional
        if let deprecatedVersionsRange = deprecatedVersions, check(value: appVersion, in: deprecatedVersionsRange) {
            style = .required
        } else {
            style = .recommended
        }

        return UpdateAppViewController(style: style)
    }

    private func check(value: String, in range: String) -> Bool {
        let ranges = range.split(separator: ",")
        for range in ranges {
            let minVersion = range.components(separatedBy: "..")[0]
            let maxVersion = range.components(separatedBy: "..")[1]

            if value >= minVersion && value <= maxVersion {
                return true
            }
        }

        return false
    }
}
