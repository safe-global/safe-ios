//
//  TrackingEvent.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

enum TrackingUserProperty: String, UserProperty {
    case numSafes = "num_safes" // string, number of user safes, "0" on fresh install
    case pushInfo = "push_info" // string: ["unknown", "disabled", "enabled"]
    case numKeysImported = "num_keys_imported" // string, number of keys imported, "0" on fresh install
    case numKeysGenerated = "num_keys_generated" // string, number of keys generated, "0" on fresh install
    case numKeysWalletConnect = "num_keys_walletconnect" // string, number of WalletConnect keys, "0" on fresh install
    case numKeysLedgerNanoX = "num_keys_ledger_nano_x" // string, number of Ledger Nano X keys, "0" on fresh install
    case passcodeIsSet = "passcode_is_set" // string, "true" or "false" depending on if app passcode is set
    case walletConnectForDappsEnabled = "wc_for_dapps_enabled" // string, "true" or "false"
    case walletConnectForKeysEnabled = "wc_for_keys_enabled" // string, "true" or "false"
    case desktopPairingEnabled = "desktop_pairing_enabled" // string, "true" or "false"
}

enum TrackingPushState: String {
    case unknown, disabled, enabled
}

enum TrackingEvent: String, Trackable {
    case launch                                     = "screen_launch"
    case launchTems                                 = "screen_launch_terms"

    case assetsNoSafe                               = "screen_assets_no_safe"
    case assetsCoins                                = "screen_assets_coins"
    case assetsCollectibles                         = "screen_assets_collectibles"
    case assetsCollectiblesDetails                  = "screen_assets_collectibles_details"
    case collectiblesNotSupported                   = "screen_collectibles_not_supported"
    case collectiblesOpenInWeb                      = "user_collectibles_open_in_web"

    case safeReceive                                = "screen_safe_receive"
    case safeSwitch                                 = "screen_safe_switch"
    case safeAddAddress                             = "screen_safe_add_address"
    case safeAddName                                = "screen_safe_add_name"
    case safeAddEns                                 = "screen_safe_add_ens"
    case safeAddUd                                  = "screen_safe_add_ud"
    case networkSelect                              = "screen_chain_list"

    case transactionsQueued                         = "screen_transactions_queue"
    case transactionsHistory                        = "screen_transactions_history"
    case transactionsNoSafe                         = "screen_transactions_no_safe"
    case transactionsDetails                        = "screen_transactions_details"
    case transactionDetailsRejectionConfirmation    = "screen_transactions_reject_confirmation"

    case transactionsDetailsAdvanced                = "screen_transactions_details_advanced"
    case transactionsDetailsAction                  = "screen_transaction_details_action"
    case transactionDetailsActionList               = "screen_transaction_details_action_list"
    case transactionDetailsTransactionConfirmed     = "user_transaction_confirmed"
    case transactionDetailsTxConfirmedWC            = "user_transaction_confirmed_walletconnect"
    case transactionDetailsTxConfirmedLedgerNanoX   = "user_transaction_confirmed_ledger_nano_x"
    case transactionDetailsTransactionRejected      = "user_transaction_rejected"
    case transactionDetailsTxRejectedWC             = "user_transaction_rejected_walletconnect"
    case transactionDetailsTxRejectedLedgerNanoX    = "user_transaction_rejected_ledger_nano_x"
    case transactionDetailsTxExecutedWC             = "user_transaction_executed_walletconnect"

    case dapps                                      = "screen_dapps"
    case dappsNoSafe                                = "screen_dapps_no_safe"

    case settingsApp                                = "screen_settings_app"
    case settingsAppAdvanced                        = "screen_settings_app_advanced"
    case settingsAppEditFiat                        = "screen_settings_app_edit_fiat"
    case settingsAppSupport                         = "screen_settings_app_support"

    case addressBookList                            = "screen_address_book_list"
    case addressBookAddEntry                        = "screen_adderess_book_add"
    case addressBookEditEntry                       = "screen_address_book_edit"
    case addressBookImported                        = "address_book_imported"
    case addressBookExported                        = "address_book_exported"

    case settingsSafe                               = "screen_settings_safe"
    case settingsSafeNoSafe                         = "screen_settings_safe_no_safe"
    case settingsSafeEditName                       = "screen_settings_safe_edit_name"
    case settingsSafeAdvanced                       = "screen_settings_safe_advanced"

    case appUpdateDeprecated                        = "screen_update_deprecated"
    case appUpdateDeprecatedSoon                    = "screen_update_deprecated_soon"
    case appUpdateOptional                          = "screen_update_new_version"

    case userOnboardingOwnerSkip                    = "user_onboarding_owner_skip"
    case userOnboardingOwnerAdd                     = "user_onboarding_owner_add"
    case ownerKeysList                              = "screen_owner_list"
    case ownerKeysOptions                           = "screen_owner_options"
    case ownerKeyDetails                            = "screen_owner_details"
    case editOwnerKey                               = "screen_owner_edit_name"

    case importOwnerOnboarding                      = "screen_owner_info"
    case generateOwnerOnboarding                    = "screen_owner_generate_info"
    case connectOwnerOnboarding                     = "screen_owner_walletconnect_info"
    case ledgerOwnerOnboarding                      = "screen_owner_ledger_nano_x_info"

    case ownerEnterSeed                             = "screen_owner_enter_seed"
    case ownerConfirmPrivateKey                     = "screen_owner_confirm_private_key"
    case ownerSelectAccount                         = "screen_owner_select_account"
    case enterKeyName                               = "screen_owner_enter_name"

    case ownerKeyImported                           = "user_key_imported"
    case ownerKeyGenerated                          = "user_key_generated"
    case ownerKeyRemoved                            = "user_key_deleted"

    case chooseOwner                                = "screen_owner_choose"
    case bannerImportOwnerKeySkipped                = "user_banner_owner_skip"
    case bannerImportOwnerKeyAdd                    = "user_banner_owner_add"
    case camera                                     = "screen_camera"

    case exportSeed                                 = "screen_owner_export_seed"
    case exportKey                                  = "screen_owner_export_key"

    case createPasscode                             = "screen_passcode_create"
    case repeatPasscode                             = "screen_passcode_create_repeat"
    case enterPasscode                              = "screen_passcode_enter"
    case changePasscode                             = "screen_passcode_change"
    case changePasscodeEnterNew                     = "screen_passcode_change_create"
    case changePasscodeRepeat                       = "screen_passcode_change_repeat"
    case settingsAppPasscode                        = "screen_settings_app_passcode"
    case userPasscodeEnabled                        = "user_passcode_enabled"
    case userPasscodeDisabled                       = "user_passcode_disabled"
    case userPasscodeReset                          = "user_passcode_reset"
    case userPasscodeSkipped                        = "user_passcode_skipped"

    case userSafeAdded                              = "user_safe_added"
    case userSafeRemoved                            = "user_safe_removed"

    case experimental                               = "screen_experimental"

    case walletConnectKeyOptions                    = "screen_owner_walletconnect_options"
    case walletConnectKeyQR                         = "screen_owner_walletconnect_qr_code"
    case connectInstalledWallet                     = "user_owner_connected_installed_wallet"
    case connectExternalWallet                      = "user_owner_connected_external_wallet"
    case dappConnectedWithUniversalLink             = "user_dapp_connected_universal_link"
    case dappConnectedWithPasteboardValue           = "user_dapp_connected_pasteboard"
    case dappConnectedWithScanButton                = "user_dapp_connected_scan_button"

    case walletConnectIncomingTransaction           = "screen_wc_incoming_transaction"
    case walletConnectEditParameters                = "screen_wc_edit_parameters"
    case incomingTxConfirmed                        = "incoming_transaction_confirmed"
    case incomingTxConfirmedWalletConnect           = "incoming_transaction_confirmed_wc"
    case incomingTxConfirmedLedger                  = "incoming_transaction_confirmed_ledger_nx"

    case ledgerKeyImported                          = "user_ledger_nano_x_key_imported"
    case ledgerSelectDevice                         = "screen_select_ledger_nano_x_device"
    case ledgerSelectKey                            = "screen_select_ledger_nano_x_key"
    case ledgerEnterKeyName                         = "screen_ledger_nano_x_enter_name"

    case desktopPairing                             = "screen_desktop_pairing"
    case desktopPairingLearnMore                    = "dp_learn_more"
    case desktopPairingConfirmConnection            = "screen_dp_confirm_connection"
    case desktopPairingConnectionConfirmed          = "dp_connection_confirmed"
    case desktopPairingConnectionRejected           = "dp_connection_rejected"
    case desktopPairingSignRequest                  = "screen_dp_sign_request"
    case dpSignRequestConfirmedPhoneKey             = "dp_sign_request_confirmed_phone_key"
    case dpSignRequestConfirmedLedger               = "dp_sign_request_confirmed_ledger_nx"
    case desktopPairingSignRequestRejected          = "dp_sign_request_rejected"

    // MARK: add delegate key
    case addDelegateKeyLedger                       = "screen_delegate_ledger_nano_x"
    case addDelegateKeyWalletConnect                = "screen_delegate_walletconnect"

    case addDelegateKeyStarted                      = "user_start_add_delegate"
    case addDelegateKeySkipped                      = "user_skip_add_delegate"
    case addDelegateKeySuccess                      = "user_success_add_delegate"
    case addDelegateKeyFailed                       = "user_failed_add_delegate"
}
