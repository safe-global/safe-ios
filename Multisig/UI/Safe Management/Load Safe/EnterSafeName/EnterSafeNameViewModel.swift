//
//  EnterSafeNameViewModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class EnterSafeNameViewModel: ObservableObject {

    @Published
    var enteredText: String = ""

    @Published
    var isValid: Bool?

    var validatedText: String {
        enteredText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var address: String

    private var subscribers = Set<AnyCancellable>()

    init(address: String) {
        self.address = address
        
        $enteredText
            .dropFirst()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .sink { [unowned self] value in
                self.isValid = !value.isEmpty
            }
            .store(in: &subscribers)
    }

    func onEditing() {
        self.isValid = validatedText.isEmpty ? nil : true
    }

    func submit() {
        guard isValid == true else { return }
        Safe.create(address: address, name: validatedText)
    }

}
