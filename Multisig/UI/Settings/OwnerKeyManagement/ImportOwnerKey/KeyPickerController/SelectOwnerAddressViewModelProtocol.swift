//
//  SelectOwnerAddressViewModelProtocol.swift
//  Multisig
//
//  Created by Zhiying Fan on 17/9/2022.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct KeyAddressInfo {
    var index: Int
    var address: Address
    var name: String?
    var exists: Bool { name != nil }
}

protocol SelectOwnerAddressViewModelProtocol {
    var items: [KeyAddressInfo] { get set }
    var selectedIndex: Int { get set }
    var pageSize: Int { get set }
    var maxItemCount: Int { get }
    var selectedPrivateKey: PrivateKey? { get }
    var selectedKeystoneKeyParameters: AddKeystoneKeyParameters? { get }
    var canLoadMoreAddresses: Bool { get }
    func generateNextPage()
}
