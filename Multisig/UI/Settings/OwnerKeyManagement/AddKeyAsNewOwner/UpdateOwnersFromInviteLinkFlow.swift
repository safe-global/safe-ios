//
//  AddOwnerFromInviteLinkFlow.swift
//  Multisig
//
//  Created by Moaaz on 6/16/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
///
/// Flow that update  owners of a safe.
///
/// Expects that paramters are passed.
///
///
/// Screen sequence:
///
/// 1. Validate paramter and check if safe, owner and chain is there
/// 2. Select whether add/replace owner
/// 3. Start the corresponding flow
///
class UpdateOwnersFromInviteLinkFlow: UIFlow {
    var parameters: AddOwnerRequestParameters!

    private var replaceOwnerFlow: ReplaceOwnerFromInviteFlow!
    private var addOwnerFlow: AddOwnerFromInviteFlow!
    
    init(parameters: AddOwnerRequestParameters, completion: @escaping (_ success: Bool) -> Void) {
        self.parameters = parameters
        super.init(completion: completion)
    }

    override func start() {
        validateInviteLink()
    }

    func validateInviteLink() {
        let vc = ValidateRequestToAddOwnerViewController()
        vc.parameters = parameters
        vc.onCancel = { [unowned self] in
            stop(success: false)
        }

        vc.onAddOwner = { [unowned self] (safe, owner) in
            addOwner(safe: safe, owner: owner)
        }

        vc.onReplaceOwner = { [unowned self] (safe, owner) in
            replaceOwner(safe: safe, owner: owner)
        }

        show(vc)
    }

    func addOwner(safe: Safe, owner: Address) {
        addOwnerFlow = AddOwnerFromInviteFlow(newOwner: owner, safe: safe) { [unowned self] success in
            addOwnerFlow = nil
            completion(success)
        }

        push(flow: addOwnerFlow)
    }

    func replaceOwner(safe: Safe, owner: Address) {
        replaceOwnerFlow = ReplaceOwnerFromInviteFlow(newOwner: owner, safe: safe) { [unowned self] success in
            replaceOwnerFlow = nil
            completion(success)
        }

        push(flow: replaceOwnerFlow)
    }
}
