//
//  GnosisError.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 14.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

protocol DetailedLocalizedError: LocalizedError, LoggableError {
    var description: String { get }
    var reason: String { get }
    var howToFix: String { get }
    var loggable: Bool { get }
}

extension DetailedLocalizedError {
    var errorDescription: String? {
        return "\(description): \(reason) \(howToFix) (Error \(code))"
    }
}

/// Gnosis Safe errors as specified here in the requirements
enum GSError {
    private static let networkErrorDomain = "NetworkError"
    private static let clientErrorDomain = "CommonClientError"
    private static let iOSErrorDomain = "iOSError"

    private static func unexpectedError(_ code: Int = 0) -> Error {
        let errorID = Int("422\(code)") ?? code
        return UnprocessableEntity(
            reason: "Network request failed with an unexpected error.", code: errorID)
    }

    /// User facing error from underlying error
    /// - Parameters:
    ///   - description: User facing description
    ///   - error: undrelying error
    /// - Returns: Detailed localized error
    static func error(description: String, error: Error? = nil) -> DetailedLocalizedError {
        struct AppError: DetailedLocalizedError {
            let description: String
            let reason: String
            let howToFix: String
            let domain: String
            let code: Int
            let loggable: Bool
        }

        if let error = error as? DetailedLocalizedError {
            return AppError(description: description,
                            reason: error.reason,
                            howToFix: error.howToFix,
                            domain: error.domain,
                            code: error.code,
                            loggable: error.loggable)
        } else if let error = error as? LocalizedError {
            return UnknownAppError(description: description,
                                   reason: error.failureReason ?? error.localizedDescription,
                                   howToFix: error.recoverySuggestion ?? "")
        } else if let error = error as NSError? {
            return UnknownAppError(
                description: description,
                reason: error.localizedFailureReason ?? error.localizedDescription,
                howToFix: error.localizedRecoverySuggestion ?? "")
        } else {
            return UnknownAppError(
                description: description,
                reason: "",
                howToFix: "")
        }
    }

    static func detailedError(from error: Error) -> Error {
        guard let nsError = error as NSError?, nsError.domain == NSURLErrorDomain else { return error }
        switch URLError.Code(rawValue: nsError.code) {
        case .notConnectedToInternet:
            return NoInternet()
        case .secureConnectionFailed:
            return SecureConnectionFailed()
        case .timedOut:
            return TimeOut()
        case .cannotFindHost:
            return UnknownHost()
        default:
            return error
        }
    }

    static func detailedError(from httpResponse: HTTPURLResponse, data: Data?) -> Error {
        switch httpResponse.statusCode {
        case 200...299:
            preconditionFailure("Not an error, please check the calling code")
        case 404:
            return EntityNotFound()
        case 422:
            return unprocessableEntity(data: data)
        case 300...599:
            return ServerSideError(code: httpResponse.statusCode)
        default:
            let error = UnknownNetworkError(code: httpResponse.statusCode)
            LogService.shared.error("Unknown error with status code: \(httpResponse.statusCode)", error: error)
            return UnknownNetworkError(code: httpResponse.statusCode)
        }
    }

    private static func unprocessableEntity(data: Data?) -> Error {
        guard let data = data else {
            LogService.shared.error("Missing data in unprocessableEntity error", error: unexpectedError())
            return unexpectedError()
        }

        do {
            let error = try JSONDecoder().decode(BackendError.self, from: data)
            switch error.code {
            case 1:
                return UnprocessableEntity(reason: "Address format is not valid.", code: 42201)
            case 50:
                return UnprocessableEntity(reason: "Safe Account info is not found.", code: 42250)
            default:
                LogService.shared.error(
                    "Unrecognised error with code: \(error.code); message: \(error.message ?? "")",
                    error: unexpectedError(error.code))
                return unexpectedError(error.code)
            }
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? data.base64EncodedString()
            LogService.shared.error("Could not decode error details from the data: \(dataString)",
                                    error: unexpectedError())
            return unexpectedError()
        }
    }

    fileprivate struct BackendError: Decodable {
        let code: Int
        let message: String?
    }

    // MARK: - Network errors

    struct NoInternet: DetailedLocalizedError {
        let description = "No Internet"
        let reason = "Device is not connected to the Internet."
        let howToFix = "Please try again when Internet is available"

        let domain = networkErrorDomain
        let code = 101
        let loggable = false
    }

    struct SecureConnectionFailed: DetailedLocalizedError {
        let description = "SSL connection failed"
        let reason = "SSL connection failed."
        let howToFix = "Please try again later"

        let domain = networkErrorDomain
        let code = 102
        let loggable = false
    }

    struct TimeOut: DetailedLocalizedError {
        let description = "Request timed out"
        var reason: String { "Request timed out after \(String(format: "%.0f", timeOut))s." }
        let howToFix = "Please refresh the screen"

        let domain = networkErrorDomain
        let code = 103
        let loggable = false

        let timeOut = HTTPClient.timeOutIntervalForRequest
    }

    struct UnknownHost: DetailedLocalizedError {
        let description = "Unknown host, connection error"
        let reason = "Server not reachable."
        let howToFix = "Please try again when Internet is available"

        let domain = networkErrorDomain
        let code = 104
        let loggable = false
    }

    struct EntityNotFound: DetailedLocalizedError {
        let description = "HTTP 404 Not Found"
        let reason = "Safe Account not found."
        let howToFix = "Please check that the Safe Account exists on the blockchain"
        let domain = networkErrorDomain
        let code = 404
        let loggable = false
    }

    struct UnprocessableEntity: DetailedLocalizedError {
        let description = "HTTP 422 Unprocessable Entity"
        let reason: String
        let howToFix = "Please try again later"
        let domain = networkErrorDomain
        let code: Int
        let loggable = true
    }

    struct ServerSideError: DetailedLocalizedError {
        let description = "HTTP 3xx, 4xx, 5xx"
        let reason = "Server-side error."
        let howToFix = "Please try again later or contact Safe support if the issue persists"
        let domain = networkErrorDomain
        let code: Int
        let loggable = false
    }

    struct UnknownNetworkError: DetailedLocalizedError {
        let description = "Unknown error"
        let reason = "Unexpected network error."
        let howToFix = "Please reach out to the Safe support"
        let domain = networkErrorDomain
        let code: Int
        let loggable = true
    }

    // MARK: - Common client errors

    struct SafeAlreadyExists: DetailedLocalizedError {
        let description = "Can’t use this address"
        let reason = "A Safe Account with this address has been added already."
        let howToFix = "Please use another Safe Account address"
        let domain = clientErrorDomain
        let code = 1101
        let loggable = false
    }

    struct SafeAddressNotValid: DetailedLocalizedError {
        let description = "This address is not valid"
        let reason = "This value is not a valid address."
        let howToFix = "Please use the checksummed Safe Account address"
        let domain = clientErrorDomain
        let code = 1102
        let loggable = false
    }

    struct WrongSeedPhrase: DetailedLocalizedError {
        let description = "Can’t use this seed phrase"
        let reason = "This is not a valid seed phrase for an Ethereum account."
        let howToFix = "Please correct the error or use another seed phrase"
        let domain = clientErrorDomain
        let code = 1103
        let loggable = false
    }

    struct AddressMismatchNetwork: DetailedLocalizedError {
        let description = "Can’t use this address"
        let reason = "This address is not matching the selected network."
        let howToFix = "Please use a different address or switch network"
        let domain = clientErrorDomain
        let code = 1104
        let loggable = false
    }

    struct KeyAlreadyImported: DetailedLocalizedError {
        let description = "Can't use this private key"
        let reason = "This key already imported."
        let howToFix = "Please import a different key"
        let domain = clientErrorDomain
        let code = 1111
        let loggable = false
    }

    struct MissingPrivateKeyError: DetailedLocalizedError {
        let description = "Failed to confirm transaction"
        let reason = "Private key not found"
        let howToFix = "Please import different owner key"
        let domain = clientErrorDomain
        let code = 1112
        let loggable = false
    }

    struct SignerMismatch: DetailedLocalizedError {
        let description = "Failed to sign transaction"
        let reason = "Signature does not match selected owner."
        let howToFix = "Please sign with selected owner"
        let domain = clientErrorDomain
        let code = 1114
        let loggable = false
    }

    struct TransactionSigningError: DetailedLocalizedError {
        let description = "Failed to confirm transaction"
        let reason = "Computed safeTxHash of a transaction to confirm does not match server-returned value."
        let howToFix = "Please reload the data or check that your network is secure"
        let domain = clientErrorDomain
        let code = 1104
        let loggable = false
    }

    struct UnsupportedImplementationCopy: DetailedLocalizedError {
        let description = "Unsupported Safe Account base contract"
        let reason = "The base contract of your Safe Account is not supported by this app."
        let howToFix = "Please change the base contract before adding it or use another Safe Account"
        let domain = clientErrorDomain
        let code = 1105
        let loggable = false
    }

    struct ENSAddressNotFound: DetailedLocalizedError {
        let description = "Can’t use this name"
        let reason = "Address not found."
        let howToFix = "Please enter a valid ENS name"
        let domain = clientErrorDomain
        let code = 1106
        let loggable = false
    }

    struct ENSInvalidCharacters: DetailedLocalizedError {
        let description = "Can’t use this name"
        let reason = "ENS name is invalid."
        let howToFix = "Please enter a valid ENS name"
        let domain = clientErrorDomain
        let code = 1108
        let loggable = false
    }

    struct InvalidSafeAddress: DetailedLocalizedError {
        let description = "Invalid Safe Account address"
        let reason = "Safe Account not found."
        let howToFix = "Please check that the Safe Account exists on the blockchain"
        let domain = clientErrorDomain
        let code = 1109
        let loggable = false
    }

    struct InvalidSafeName: DetailedLocalizedError {
        let description = "Can’t use this name"
        let reason = "This value is not a valid name."
        let howToFix = "Name should not be empty"
        let domain = clientErrorDomain
        let code = 1110
        let loggable = false
    }

    struct ChainIdMismatch: DetailedLocalizedError {
        let description = "Trying to update a chain with different id"
        let reason = "Trying to update a chain with different id"
        let howToFix = "Chain Id should be identical"
        let domain = clientErrorDomain
        let code = 1111
        let loggable = false
    }
    
    struct CreateSafeFailed: DetailedLocalizedError {
        let description = "Failed to create a Safe Account"
        let reason = "Submitting failed"
        let howToFix = "Please try to resubmit later"
        let domain = clientErrorDomain
        let code = 1112
        let loggable = false
    }

    struct DelagateToSameSafe: DetailedLocalizedError {
        let description = "The Safe Account address can't be a delegate of itself"
        let reason = "Please choose another address or select a guardian"
        let howToFix = "Your Safe Account always has the full voting power even after delegating to another address"
        let domain = clientErrorDomain
        let code = 1113
        let loggable = false
    }
    

    // MARK: - WalletConnect experimental feature errors

    struct InvalidWalletConnectQRCode: DetailedLocalizedError {
        let description = "Can’t use this QR code"
        let reason = "Scanned QR code is not in the format that we expect."
        let howToFix = "Please assure that the displayed QR code is in a valid format"
        let domain = clientErrorDomain
        let code = 9901
        let loggable = false
    }

    struct CouldNotStartWallectConnectSession: DetailedLocalizedError {
        let description = "Could not start a session"
        let reason = "We could not start a session with this QR code."
        let howToFix = "Please try with another QR code"
        let domain = clientErrorDomain
        let code = 9902
        let loggable = false
    }

    struct CouldNotSignWithWalletConnect: DetailedLocalizedError {
        let description = "Could not sign with connected wallet"
        let reason = "Wallet rejected the request."
        let howToFix = "Please confirm the request with your wallet."
        let domain = clientErrorDomain
        let code = 9903
        let loggable = false
    }

    struct CouldNotCreateWallectConnectURL: DetailedLocalizedError {
        let description = "Could not create connection URL"
        let reason = "We could not connect to the WalletConnect bridge server."
        let howToFix = "Please try again later or contact Safe support if the issue persists"
        let domain = clientErrorDomain
        let code = 9904
        let loggable = false
    }

    struct DuplicateKey: DetailedLocalizedError {
        let description = "Could not add owner key"
        let reason = "The owner key is already added."
        let howToFix = "Please use the already added key or remove it and try again."
        let domain = clientErrorDomain
        let code = 9905
        let loggable = false
    }

    struct WalletNotConnected: DetailedLocalizedError {
        let description: String
        let reason = "The owner key is not connected."
        let howToFix = "Please connect your owner key via WalletConnect."
        let domain = clientErrorDomain
        let code = 9906
        let loggable = false
    }

    struct KeyConnectionProblem: DetailedLocalizedError {
        let description: String = "Can't use this account"
        let reason = "wrong network selected."
        let howToFix = "Please change the selected network of the connected key."
        let domain = clientErrorDomain
        let code = 9907
        let loggable = false
    }

    struct WCConnectedKeyMissingAddress: DetailedLocalizedError {
        let description: String = "Can't add the key"
        let reason = "Connected wallet did not provide key address"
        let howToFix = "Please re-connect the key again and select an account in your wallet."
        let domain = clientErrorDomain
        let code = 9908
        let loggable = false
    }

    struct WCConnectedKeyNotFound: DetailedLocalizedError {
        let description: String = "Can't find connected key"
        let reason = "Couldn't find key provided by the wallet"
        let howToFix = "Please import key"
        let domain = clientErrorDomain
        let code = 9909
        let loggable = false
    }

    // MARK: - WalletConnect V2

    struct WC2PairingFailed: DetailedLocalizedError {
        let description: String = "Pairing failed"
        let reason = "Unknown"
        let howToFix = "Please try again later"
        let domain = clientErrorDomain
        let code = 9920
        let loggable = false
    }

    struct WC2PairingAlreadyExists: DetailedLocalizedError {
        let description: String = "Pairing failed"
        let reason = "You cannot use the same QR code twice."
        let howToFix = "Please try again with a different QR code or WalletConnect URL"
        let domain = clientErrorDomain
        let code = 9921
        let loggable = false
    }

    struct WC2SessionApprovalFailed: DetailedLocalizedError {
        let description: String = "Session not approved"
        let reason = "Unknown"
        let howToFix = "Please try again later"
        let domain = clientErrorDomain
        let code = 9930
        let loggable = false
    }

    struct WC2SessionApprovalFailedWrongChain: DetailedLocalizedError {
        let description: String = "Session not approved"
        let reason = "Wrong chain"
        let howToFix = "Please use selected Safe Accounts' chain"
        let domain = clientErrorDomain
        let code = 9931
        let loggable = false
    }

	// MARK: Address Book

    struct AddressBookEntryAlreadyExists: DetailedLocalizedError {
        let description = "Can’t use this address"
        let reason = "An entry with this address has been added already."
        let howToFix = "Please use another address"
        let domain = clientErrorDomain
        let code = 8001
        let loggable = false
    }

    struct AddressNotValid: DetailedLocalizedError {
        let description = "This address is not valid"
        let reason = "This value is not a valid address."
        let howToFix = "Please use the checksummed address"
        let domain = clientErrorDomain
        let code = 8002
        let loggable = false
    }

    // MARK: - iOS errors

    struct UnknownAppError: DetailedLocalizedError {
        let description: String
        let reason: String
        let howToFix: String
        let domain = iOSErrorDomain
        let code = 1300
        let loggable = true
    }

    struct PreconditionsForSigningNotSatisfied: DetailedLocalizedError {
        let description: String
        let reason = "Something is wrong either with the transaction data or with the application state (database, selected Safe Account, etc.)"
        let howToFix = "Please try again later or contact Safe support if this issue persists"
        let domain = iOSErrorDomain
        let code = 1304
        let loggable = true
    }

    struct KeychainError: DetailedLocalizedError {
        let description = "Keychain error"
        let reason: String
        let howToFix = "Please try again later or contact Safe support if this issue persists"
        let domain = iOSErrorDomain
        let code = 1305
        let loggable = true
    }

    struct CancelledByUser: DetailedLocalizedError {
        let description = ""
        let reason = "The operation is canceled by user"
        let howToFix = ""
        let domain = clientErrorDomain
        let code = 1307
        let loggable = false
    }

    struct DatabaseError: DetailedLocalizedError {
        let description = "Database error"
        let reason: String
        let howToFix = "Please try again later or contact Safe support if this issue persists"
        let domain = iOSErrorDomain
        let code = 1306
        let loggable = true
    }

    struct ThirdPartyError: DetailedLocalizedError {
        let description = "Third party library error"
        let reason: String
        let howToFix = "Please try again later or contact Safe support if this issue persists"
        let domain = iOSErrorDomain
        let code = 1311
        let loggable = true
    }

    struct GenericPasscodeError: DetailedLocalizedError {
        let description = "Failed to set passcode"
        let reason: String
        let howToFix = "Please try again later or contact Safe support if this issue persists"
        let domain = iOSErrorDomain
        let code = 1312
        let loggable = false
    }

    struct BiometryActivationError: DetailedLocalizedError {
        let description = "Failed to enable biometry"
        var reason: String { underlyingError.localizedDescription }
        let underlyingError: Error
        let howToFix = "Please try again"
        let domain = iOSErrorDomain
        let code = 1313
        let loggable = false
    }

    struct BiometryAuthenticationError: DetailedLocalizedError {
        let description = "Failed to login with biometry"
        var reason: String { underlyingError.localizedDescription }
        let underlyingError: Error
        let howToFix = "Please try again"
        let domain = iOSErrorDomain
        let code = 1314
        let loggable = false
    }

    struct PrivateKeyDataNotFound: DetailedLocalizedError {
        let description = "Failed to find private key data"
        let reason: String
        let howToFix = "Please remove this key"
        let domain = iOSErrorDomain
        let code = 1315
        let loggable = true
    }

    struct PrivateKeyFetchError: DetailedLocalizedError {
        let description = "Failed to fetch private key"
        let reason: String
        let howToFix = "Please try again"
        let domain = iOSErrorDomain
        let code = 1316
        let loggable = true
    }

    struct ProblemConnectingBluetoothDevice: DetailedLocalizedError {
        let description = "Failed to connect"
        let reason = "The Bluetooth device is not powered on."
        let howToFix = "Please check the bluetooth status on your phone."
        let domain = iOSErrorDomain
        let code = 1317
        let loggable = false
    }

    struct BluetoothIsNotAuthorized: DetailedLocalizedError {
        let description = "Failed to connect"
        let reason = "The Bluetooth device is not authorized."
        let howToFix = "Please check the bluetooth status in the app settings."
        let domain = iOSErrorDomain
        let code = 1318
        let loggable = false
    }

    struct FileManagerError: DetailedLocalizedError {
        let description = "Failed to access files"
        let reason = "The app is not able to access files"
        let howToFix = "Please try again."
        let domain = iOSErrorDomain
        let code = 1319
        let loggable = false
    }

    // MARK: Delegate Key Errors

    struct OwnerKeyNotFoundForDelegate: DetailedLocalizedError {
        let description = "Failed to set up push notifications"
        let reason = "Owner key not found for delegate key"
        let howToFix = "Please make sure that the owner key exists"
        let domain = iOSErrorDomain
        let code = 1320
        let loggable: Bool = false
    }

    struct UnrecognizedKeyTypeForDelegate: DetailedLocalizedError {
        let description = "Failed to set up push notifications"
        let reason = "Expected to use ledger key but a different type provided"
        let howToFix = "Please select a ledger key and try again"
        let domain = iOSErrorDomain
        let code = 1321
        let loggable: Bool = false
    }

    struct AddDelegateKeyCancelled: DetailedLocalizedError {
        let description = "Push notifications are not set"
        let reason = "The operation is canceled by user"
        let howToFix = ""
        let domain = iOSErrorDomain
        let code = 1322
        let loggable: Bool = false
    }

    struct AddDelegateTimedOut: DetailedLocalizedError {
        let description = "Push notifications were not set properly"
        let reason = "Request to server timed out"
        let howToFix = "Please try again later"
        let domain = iOSErrorDomain
        let code = 1323
        let loggable: Bool = false
    }

    struct DeleteDelegateTimedOut: DetailedLocalizedError {
        let description = "Push notifications were not disabled properly"
        let reason = "Request to server timed out"
        let howToFix = "Please try again later"
        let domain = iOSErrorDomain
        let code = 1324
        let loggable: Bool = false
    }

    struct RequiredPasscode: DetailedLocalizedError {
        let description = "Failed to get passcode"
        let reason = "Your passcode is required to perform this operation"
        let howToFix = "Enter correct passcode and try again"
        let domain = iOSErrorDomain
        let code = 1325
        let loggable = false
    }

    struct FailedToChangePasscode: DetailedLocalizedError {
        let description = "Failed to change passcode"
        let reason: String
        let howToFix = "Enter correct passcode and try again"
        let domain = iOSErrorDomain
        let code = 1326
        let loggable = false
    }
    
    struct Web3AuthGenericError: DetailedLocalizedError {
        let description = "Failed to log in"
        var reason: String { underlyingError.localizedDescription }
        let underlyingError: Error
        let howToFix = "Please try again"
        let domain = iOSErrorDomain
        let code = 1327
        let loggable = false
    }


    // - MARK: - Unstoppable domain errors

    struct UDUnsuportedName: DetailedLocalizedError {
        let description = "Can't use this name"
        let reason = "Invalid domain name"
        let howToFix = "Please check the domain, it should end with .crypto or .zil"
        let domain = clientErrorDomain
        let code = 6357
        let loggable = false
    }

    struct UDUnregisteredName: DetailedLocalizedError {
        let description = "Address not found"
        let reason = "This domain is not registered with UD."
        let howToFix = "Check if domain is correct"
        let domain = clientErrorDomain
        let code = 6358
        let loggable = false
    }

    struct UDResolverNotFound: DetailedLocalizedError {
        let description = "Can't use this name"
        let reason = "Domain is not configured correctly."
        let howToFix = "Ask Domain owner to configure resolver contract"
        let domain = clientErrorDomain
        let code = 6360
        let loggable = false
    }

    struct UDUnsupportedNetwork: DetailedLocalizedError {
        let description = "Incorrect network"
        let reason = "Selected network is not supported by Unstoppable Domains."
        let howToFix = "Make sure you are connected to the mainnet or rinkeby to operate"
        let domain = clientErrorDomain
        let code = 6362
        let loggable = false
    }

    struct UDDecodingError: DetailedLocalizedError {
        let description = "Unexpected server response"
        let reason = "Can't decode response from the server."
        let howToFix = "Please try another domain"
        let domain = clientErrorDomain
        let code = 6363
        let loggable = false
    }

    struct UDEncodingError: DetailedLocalizedError {
        let description = "Error creating server request"
        let reason = "Can't encode request to the server."
        let howToFix = "Please try another domain or try again later"
        let domain = clientErrorDomain
        let code = 6364
        let loggable = false
    }

    // MARK: - Keystone Errors

    struct KeystoneSignFailed: DetailedLocalizedError {
        let description = "Error during signing"
        let reason = "Can't understand received signature."
        let howToFix = "Please reach out to the support"
        let domain = clientErrorDomain
        let code = 2100
        let loggable = false
    }

    struct KeystoneStartSignFailed: DetailedLocalizedError {
        let description = "Error during signing"
        let reason = "Can't create signature request."
        let howToFix = "Please reach out to the support"
        let domain = clientErrorDomain
        let code = 2101
        let loggable = false
    }

}
