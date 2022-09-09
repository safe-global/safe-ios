//
//  Guardian.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct Guardian: Decodable {
    let name: String?
    let reason: String?
    let contribution: String?
    let address: AddressString
    let ens: String?
    let image: String?
    var imageURL: URL? {
        guard let image = image else {
            return nil
        }
        return URL(string: "\(App.configuration.services.claimingDataURL)guardians/images/\(image)")
    }

    func imageURL(scale: Int) -> URL? {
        guard (1...3).contains(scale) else { return nil }
        return URL(string: "\(App.configuration.services.claimingDataURL)guardians/images/\(address.address.checksummed)_\(scale)x.png")
    }
}
