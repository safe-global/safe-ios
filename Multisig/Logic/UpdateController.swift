//
//  AppUpdateManager.swift
//  Multisig
//
//  Created by Moaaz on 4/16/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import Version

class UpdateController {

    func makeUpdateAppViewController() -> UpdateAppViewController? {
        let remoteConfig = FirebaseRemoteConfig.shared
        let appVersion = App.configuration.app.marketingVersion

        guard let latestAppVersion = remoteConfig.value(key: .newestVersion),
              !latestAppVersion.isEmpty else { return nil }

        if appVersion == latestAppVersion { return nil }
        let deprecatedVersions = remoteConfig.value(key: .deprecated)
        let deprecatedSoonVersions = remoteConfig.value(key: .deprecatedSoon)
        var style = UpdateAppViewController.Style.optional
        if let deprecatedVersionsRange = deprecatedVersions, check(value: appVersion, in: deprecatedVersionsRange) {
            style = .required
            AppSettings.lastIgnoredUpdateVersion = nil
        } else if let deprecatedSoonVersionsRange = deprecatedSoonVersions, check(value: appVersion, in: deprecatedSoonVersionsRange) {
            style = .recommended
            AppSettings.lastIgnoredUpdateVersion = nil
        } else if latestAppVersion == AppSettings.lastIgnoredUpdateVersion {
            return nil
        } else {
            AppSettings.lastIgnoredUpdateVersion = latestAppVersion
        }

        return UpdateAppViewController(style: style)
    }

    private func check(value: String, in range: String) -> Bool {
        guard !range.isEmpty, let version = Version(value) else { return false }
        let ranges = range.split(separator: ",")
        for range in ranges {
            let rangeBound = range.components(separatedBy: "...")
            let minVersion = rangeBound.first!
            let maxVersion = rangeBound.last!

            if let minVersion = Version(minVersion),
               let maxVersion = Version(maxVersion),
               version >= minVersion,
               version <= maxVersion {
                return true
            }
        }

        return false
    }
}
