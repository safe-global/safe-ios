//
//  AddSafeFlow.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 23.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddSafeFlow: UIFlow {
    
    private let factory = AddSafeFlowFactory()
    private var chain: SCGModels.Chain!
    private var address: Address!
    private var safeVersion: String!
    private var name: String!
    private var createPasscodeFlow: CreatePasscodeFlow!
    private var inputChainId: String?
    private var inputAddress: String?
    
    init(chainId: String? = nil, address: String? = nil, completion: @escaping (Bool) -> Void) {
        inputChainId = chainId
        inputAddress = address
        super.init(completion: completion)
    }
    
    override func start() {
        selectNetwork()
    }
    
    func selectNetwork() {
        let vc = factory.selectNetwork(chainId: inputChainId) { [weak self] chain in
            guard let self = self else { return }
            self.chain = chain
            self.enterAddress()
        }
        show(vc)
    }
    
    func enterAddress() {
        let vc = factory.enterAddress(chain: chain, address: inputAddress) { [weak self] address, safeVersion in
            guard let self = self else { return }
            self.address = address
            self.safeVersion = safeVersion
            self.enterName()
        }
        show(vc)
    }
    
    func enterName() {
        let vc = factory.enterName(chain: chain, address: address) { [weak self] name in
            guard let self = self else { return }
            self.name = name
            self.saveData()
            self.setupPasscode()
        }
        show(vc)
    }
    
    func saveData() {
        let coreDataChain = Chain.createOrUpdate(chain)
        Safe.create(
            address: address.checksummed,
            version: safeVersion,
            name: name,
            chain: coreDataChain)
    }
    
    func setupPasscode() {
        guard AppSettings.shouldOfferToSetupPasscode else {
            afterSetupPasscode()
            return
        }
        
        let vc = factory.setupPasscode(doSetup: { [weak self] in
            self?.openPasscodeFlow()
        }, completion: { [weak self] in
            self?.afterSetupPasscode()
        })
        show(vc)
    }
    
    func openPasscodeFlow() {
        createPasscodeFlow = CreatePasscodeFlow(completion: { [weak self] _ in
            self?.createPasscodeFlow = nil
            self?.afterSetupPasscode()
        })
        push(flow: createPasscodeFlow)
    }
    
    func afterSetupPasscode() {
        setupSignerAccount()
    }
    
    func setupSignerAccount() {
        if !AppSettings.hasShownImportKeyOnboarding && !OwnerKeyController.hasPrivateKey {
            
            let vc = factory.askToAddOwner(
                chain: chain,
                onAdd: { [weak self] in
                    self?.addOwner()
                }, onSkip: { [weak self] in
                    self?.addSafeDidComplete()
            })
            show(vc)

            AppSettings.hasShownImportKeyOnboarding = true
        } else {
            addSafeDidComplete()
        }
    }
    
    func addOwner() {
        let vc = factory.addOwner { [weak self] in
            self?.addSafeDidComplete()
        }
        vc.navigationItem.hidesBackButton = true
        show(vc)
    }
    
    func addSafeDidComplete() {
        App.shared.notificationHandler.safeAdded(address: address)
        stop(success: true)
    }
}

class AddSafeFlowFactory {
    func selectNetwork(chainId: String?, completion: @escaping (SCGModels.Chain) -> Void) -> UIViewController {
        let selectNetworkVC = SelectNetworkViewController()
        selectNetworkVC.preselectedChainId = chainId
        selectNetworkVC.screenTitle = "Load Safe Account"
        selectNetworkVC.descriptionText = "Select network on which your Safe Account was created:"
        selectNetworkVC.completion = completion
        return selectNetworkVC
    }
    
    func enterAddress(chain: SCGModels.Chain, address: String?, completion: @escaping (_ address: Address, _ safeVersion: String) -> Void) -> UIViewController {
        let vc = EnterSafeAddressViewController()
        vc.chain = chain
        vc.preselectedAddress = address
        vc.completion = completion
        let ribbon = RibbonViewController(rootViewController: vc)
        ribbon.chain = vc.chain
        return ribbon
    }
    
    func enterName(chain: SCGModels.Chain, address: Address, completion: @escaping (_ name: String) -> Void) -> UIViewController {
        let enterNameVC = EnterAddressNameViewController()
        enterNameVC.trackingParameters = ["chain_id" : chain.chainId.description]

        let enterAddressWrapperVC = RibbonViewController(rootViewController: enterNameVC)
        enterAddressWrapperVC.chain = chain

        enterNameVC.address = address
        enterNameVC.prefix = chain.shortName
        enterNameVC.trackingEvent = .safeAddName
        enterNameVC.screenTitle = "Load Safe Account"
        enterNameVC.descriptionText = "Choose a name for the Safe Account. The name is only stored locally and will not be shared with us or any third parties"
        enterNameVC.actionTitle = "Next"
        enterNameVC.placeholder = "Enter name"

        enterNameVC.completion = completion
        return enterAddressWrapperVC
    }
    
    func setupPasscode(doSetup: @escaping () -> Void, completion: @escaping () -> Void) -> CreatePasscodeSuggestionViewController {
        let vc = CreatePasscodeSuggestionViewController()
        vc.onSetupPasscode = doSetup
        vc.onExit = completion
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
    
    func askToAddOwner(chain: SCGModels.Chain, onAdd addSigner: @escaping () -> Void, onSkip: @escaping () -> Void) -> UIViewController {
        let vc = SuggestToAddSignerViewController()
        vc.onAddSigner = addSigner
        vc.completion = onSkip

        let wrapperVC = RibbonViewController(rootViewController: vc)
        wrapperVC.chain = chain
        wrapperVC.hidesBottomBarWhenPushed = true
        return wrapperVC
    }
    
    func addOwner(completion: @escaping () -> Void) -> AddOwnerKeyViewController {
        AddOwnerKeyViewController(completion: completion)
    }
}
