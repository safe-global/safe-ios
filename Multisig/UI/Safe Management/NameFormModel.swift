//
//  SafeNameFormModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class SafeNameFormModel: ObservableObject {

    @Published
    var enteredText: String = ""

    @Published
    var isValid: Bool?

    private var subscribers = Set<AnyCancellable>()

    init() {
        $enteredText
        .dropFirst()
        .sink { value in
            self.isValid = !value.isEmpty
        }
        .store(in: &subscribers)
    }

    func onEditing() {
        self.isValid = enteredText.isEmpty ? nil : true
    }

}
