//
//  InMemoryUserRepository.swift
//  SwiftAccessPolicy
//
//  Created by Andrey Scherbovich on 25.03.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class InMemotyUserRepository: UserRepository {
    private var _users = [UUID: User]()

    func save(user: User) {
        _users[user.id] = user
    }

    func delete(userID: UUID) {
        _users.removeValue(forKey: userID)
    }

    func user(userID: UUID) -> User? {
        return _users[userID]
    }

    func users() -> [User] {
        return Array(_users.values)
    }
}
