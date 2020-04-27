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

    var address: String

    private var subscribers = Set<AnyCancellable>()

    init(address: String) {
        self.address = address
        
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

    func submit() {
        guard isValid == true else { return }

        // TODO: Move to business logic
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let safe = Safe(context: context)
        safe.address = address
        safe.name = enteredText

        let settings = AppSettings.getOrCreate(context: context)
        settings.selectedSafe = address

        do {
            try context.save()
        } catch {
            print(error)
            fatalError()
        }
    }

}
