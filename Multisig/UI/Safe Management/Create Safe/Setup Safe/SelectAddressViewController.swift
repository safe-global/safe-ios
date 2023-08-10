//
//  SelectAddressViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 28.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import SafeWeb3

class SelectAddressViewController: UIAlertController {
    var completion: (Address) -> Void = { _ in }
    var onError: (_ error: Error, _ text: String?) -> Void = { _, _ in }
    var chain: Chain?
    weak var presenter: UIViewController?

    convenience init(chain: Chain?, presenter: UIViewController, completion: @escaping (Address) -> Void) {
        self.init(title: nil, message: nil, preferredStyle: .multiplatformActionSheet)
        self.presenter = presenter
        self.chain = chain
        self.completion = completion

        addAction(UIAlertAction(title: "Paste from Clipboard", style: .default, handler: handlePaste(_:)))
        addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: handleScan(_:)))
        addAction(UIAlertAction(title: "Address Book", style: .default, handler: handleAddressBook(_:)))
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }

    func handlePaste(_ action: UIAlertAction) {
        let text = Pasteboard.string
        handle(text: text)
    }

    func handleScan(_ action: UIAlertAction) {
        let vc = QRCodeScannerViewController()
        vc.scannedValueValidator = { [unowned self] value in
            do {
                return try .success(validate(text: value).checksummed)
            } catch {
                return .failure(error)
            }
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        presenter?.present(vc, animated: true, completion: nil)
    }

    func handleAddressBook(_ action: UIAlertAction) {
        let addressBookVC = AddressBookListTableViewController()
        addressBookVC.filterByChain = chain
        addressBookVC.isPickerModeEnabled = true
        addressBookVC.onSelect = { [unowned addressBookVC, unowned self] address in
            addressBookVC.dismiss(animated: true) { [unowned self] in
                completion(address)
            }
        }
        let vc = ViewControllerFactory.modal(viewController: addressBookVC)
        presenter?.present(vc, animated: true)
    }

    func validate(text: String?) throws -> Address {
        // not empty
        guard let text = text, !text.isEmpty else {
            throw ValidationError.empty
        }

        // a) recognize what kind of address format is it
        // b) validate and return address

        switch text {
        case let eip681 where eip681.matches(pattern: "^ethereum:([-a-zA-Z0-9]+-)?0x[0-9a-fA-F]{40}.*$"):
            // eip-681 formats:
                // https://eips.ethereum.org/EIPS/eip-681
                // ethereum:[pay-](address|ens name)[@chain_id][/function_name]?[key=value[&key=value ...]]
            let pattern = "^ethereum:([-a-zA-Z0-9]+-)?(0x[0-9a-fA-F]{40}).*$"
            let values = eip681.capturedValues(pattern: pattern).flatMap({ $0 })

            // take last captured value because first might capture the prefix, such as 'pay-' from string 'ethereum:pay-...'
            guard let text = values.last else {
                throw ValidationError.invalid
            }
            return try address(text)


        case let eip3770 where eip3770.matches(pattern: "^[-a-zA-Z0-9]+:0x[0-9a-fA-F]{40}$"):
            // eip-3770 format:
                // https://eips.ethereum.org/EIPS/eip-3770
                // shortName:address
            let pattern = "^([-a-zA-Z0-9]+):(0x[0-9a-fA-F]{40})$"
            let values = eip3770.capturedValues(pattern: pattern).flatMap { $0 }
            guard values.count == 2, let shortName = values.first, let addressString = values.last else {
                throw ValidationError.invalid
            }

            guard let chain = Chain.by(shortName: shortName), chain == self.chain else {
                throw ValidationError.invalidChain
            }

            return try address(addressString)

        case let caip10 where caip10.matches(pattern: "^[-a-z0-9]{3,8}:[-a-zA-Z0-9]{1,32}:[a-zA-Z0-9]{1,64}$"):
            // caip-10 format:
                // https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md
                // https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md
                // namespace:reference:address
                    // namespace - describes 'kind' of blockchain, or a class of blockchains
                    // reference - blockchain identifier within the namespace
                    // address - account address (id) in the blockchain
                // eip155:1:0x1235...12
                    // eip-155 https://eips.ethereum.org/EIPS/eip-155 - introduces chain_id
            let pattern = "^([-a-z0-9]{3,8}):([-a-zA-Z0-9]{1,32}):([a-zA-Z0-9]{1,64})$"
            let values = caip10.capturedValues(pattern: pattern).flatMap { $0 }
            guard values.count == 3 else {
                throw ValidationError.invalid
            }
            let namespace = values[0]
            let reference = values[1]
            let addressString = values[2]

            guard namespace == "eip155", let chain = Chain.by(reference), chain == self.chain else {
                throw ValidationError.invalidChain
            }

            return try address(addressString)

        case let hex where hex.matches(pattern: "^0x[0-9a-fA-F]{40}$"):
            // hex: 0xabc or 0xABC or 0XABC
            // eip-55 format - checksummed address https://eips.ethereum.org/EIPS/eip-55
            return try address(hex)

        case let ens where ens.matches(pattern: #"^[^\s]+(\.[^\s]]+)*$"#):
            throw ValidationError.unsupported

        default:
            throw ValidationError.invalid
        }
    }

    func address(_ text: String) throws -> Address {
        do {
            return try Address(from: text)
        } catch EthereumAddress.Error.checksumWrong {
            throw ValidationError.wrongChecksum
        } catch EthereumAddress.Error.addressMalformed {
            throw ValidationError.invalid
        }
    }

    func handle(text: String?) {
        do {
            let address = try self.validate(text: text)
            completion(address)
        } catch {
            onError(error, text)
            App.shared.snackbar.show(message: "Can't use this address. \(error.localizedDescription)")
        }
    }

    struct ValidationError: CustomNSError {
        static var errorDomain: String { "io.gnosis.safe.selectAddress" }
        var errorCode: Int
        var message: String
        var cause: Error? = nil

        var errorUserInfo: [String : Any] {
            var result: [String: Any] = [NSLocalizedDescriptionKey: message]
            if let cause = cause {
                result[NSUnderlyingErrorKey]  = cause
            }
            return result
        }

        static let empty = ValidationError(errorCode: -1, message: "Addres should not be empty")
        static let invalid = ValidationError(errorCode: -2, message: "Value is not a valid address")
        static let unsupported = ValidationError(errorCode: -3, message: "Address is not supported")
        static let wrongChecksum = ValidationError(errorCode: -4, message: "Address checksum is not correct")
        static let invalidChain = ValidationError(errorCode: -5, message: "Address has invalid chain")
    }
}

extension SelectAddressViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidCancel() {
        presenter?.dismiss(animated: true, completion: nil)
    }

    func scannerViewControllerDidScan(_ code: String) {
        handle(text: code)
        presenter?.dismiss(animated: true, completion: nil)
    }
}

