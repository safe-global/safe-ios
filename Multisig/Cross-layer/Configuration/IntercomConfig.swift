//
// Created by Dirk Jäckel on 23.11.21.
// Copyright (c) 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

class IntercomConfig {

    func setUp() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("WARNING: Firebase config file is not found. Firebase is disabled.")
            return
        }
        FirebaseApp.configure()
    }

}