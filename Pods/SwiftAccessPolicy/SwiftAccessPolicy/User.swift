//
//  User.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct User {
    public let id: UUID
    public var encryptedPassword: String
    public var sessionRenewedAt: Date?
    public var failedAuthAttempts: Int = 0
    public var accessBlockedAt: Date?

    public init(userID: UUID, encryptedPassword: String) {
        self.id = userID
        self.encryptedPassword = encryptedPassword
    }

    mutating func updatePassword(encryptedPassword: String) {
        self.encryptedPassword = encryptedPassword
    }

    mutating func renewSession(at time: Date) {
        self.sessionRenewedAt = time
        self.failedAuthAttempts = 0
        self.accessBlockedAt = nil
    }

    mutating func denyAccess() {
        self.sessionRenewedAt = nil
        self.failedAuthAttempts += 1
    }

    mutating func blockAccess(at time: Date) {        
        self.accessBlockedAt = time
    }

    mutating func logout() {
        self.sessionRenewedAt = nil
        self.failedAuthAttempts = 0
        self.accessBlockedAt = nil
    }
}
