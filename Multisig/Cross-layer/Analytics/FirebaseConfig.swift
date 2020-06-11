//
//  FirebaseConfig.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Firebase

class FirebaseConfig {

    func setUp() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("WARNING: Firebase config file is not found. Firebase is disabled.")
            return
        }
        FirebaseApp.configure()
    }

}
