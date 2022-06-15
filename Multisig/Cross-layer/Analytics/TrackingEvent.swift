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
    case launchTerms                                = "screen_launch_terms"

    case assetsNoSafe                               = "screen_assets_no_safe"
    case assetsCoins                                = "screen_assets_coins"
    case assetsCollectibles                         = "screen_assets_collectibles"
    case assetsCollectiblesDetails                  = "screen_assets_collectibles_details"
    case collectiblesNotSupported                   = "screen_collectibles_not_supported"
    case collectiblesOpenInWeb                      = "user_collectibles_open_in_web"
    
    case assetTransferReceiveClicked                = "user_select_receive_asset"
    case assetTransferSendClicked                   = "user_select_send_asset"
    case assetTransferAddOwnerClicked               = "user_select_add_owner_to_send_assets"
    case assetsTransferSelect                       = "screen_select_asset"
    case assetsTransferAddOwner                     = "screen_add_owner_to_send_funds"
    case assetsTransferInit                         = "screen_asset_transfer"
    case assetsTransferReview                       = "screen_review_asset_transfer"
    case assetsTransferAdvancedParams               = "screen_asset_transfer_advanced_params"
    case assetsTransferSuccess                      = "screen_asset_transfer_success"
    case assetsTransferSelectedAsset                = "screen_assets_transfer_selected_asset"

    case reviewExecution                            = "screen_exec_tx_review"
    case reviewExecutionEditFee                     = "screen_edit_exec_tx_fee"
    case reviewExecutionAdvanced                    = "screen_exec_tx_review_advanced"
    case reviewExecutionSelectKey                   = "screen_select_exec_key"
    case reviewExecutionLedger                      = "screen_exec_tx_ledger_confirm"
    case executeFailure                             = "user_exec_tx_failed"
    case reviewExecutionFieldEdited                 = "user_edit_exec_tx_fee_fields"
    case reviewExecutionSelectedKeyChanged          = "user_select_exec_key_change"

    case safeReceive                                = "screen_safe_receive"
    case safeSwitch                                 = "screen_safe_switch"
    case safeAddAddress                             = "screen_safe_add_address"
    case safeAddName                                = "screen_safe_add_name"
    case safeAddEns                                 = "screen_safe_add_ens"
    case safeAddUd                                  = "screen_safe_add_ud"
    case networkSelect                              = "screen_chain_list"
    case tryDemo                                    = "user_try_demo"
    
    case transactionsQueued                         = "screen_transactions_queue"
    case transactionsHistory                        = "screen_transactions_history"
    case transactionsNoSafe                         = "screen_transactions_no_safe"
    case transactionsDetails                        = "screen_transactions_details"
    case transactionDetailsRejectionConfirmation    = "screen_transactions_reject_confirmation"

    case transactionsDetailsAdvanced                = "screen_tx_details_advanced"
    case transactionsDetailsAction                  = "screen_tx_details_action"
    case transactionDetailsActionList               = "screen_tx_details_action_list"

    case dapps                                      = "screen_dapps"
    case dappsNoSafe                                = "screen_dapps_no_safe"

    case settingsApp                                = "screen_settings_app"
    case settingsAppAdvanced                        = "screen_settings_app_advanced"
    case settingsAppEditFiat                        = "screen_settings_app_edit_fiat"
    case settingsAppSupport                         = "screen_settings_app_support"
    case settingsAppAppearance                      = "screen_settings_app_appearance"
    case settingsAppChainPrefix                     = "screen_settings_app_chain_prefix"
    case settingsTerms                              = "user_settings_open_terms"
    case settingsPrivacyPolicy                      = "user_settings_open_privacy_policy"
    case settingsLicenses                           = "user_settings_open_licenses"
    case settingsRateApp                            = "user_settings_rate_app"

    case addressBookList                            = "screen_address_book_list"
    case addressBookAddEntry                        = "screen_address_book_add"
    case addressBookEditEntry                       = "screen_address_book_edit"
    case addressBookImported                        = "address_book_imported"
    case addressBookExported                        = "address_book_exported"

    case settingsSafe                               = "screen_settings_safe"
    case settingsSafeNoSafe                         = "screen_settings_safe_no_safe"
    case settingsSafeEditName                       = "screen_settings_safe_edit_name"
    case settingsSafeAdvanced                       = "screen_settings_safe_advanced"
    case settingsTxAdvancedParams                   = "screen_settings_tx_advanced_params"

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

    case passcodeSuggestion                         = "screen_passcode_suggestion"
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
    case userPasscodeSuggestionAccepted             = "user_passcode_suggestion_accepted"
    case userPasscodeSuggestionRejected             = "user_passcode_suggestion_rejected"
    case skipPasscodeBanner                         = "user_banner_passcode_skip"
    case setupPasscodeFromBanner                    = "user_banner_passcode_create"
    case userOpenIntercom                           = "user_settings_open_intercom"

    case userSafeAdded                              = "user_safe_added"
    case userSafeRemoved                            = "user_safe_removed"

    case experimental                               = "screen_experimental"

    case walletConnectKeyOptions                    = "screen_owner_walletconnect_options"
    case walletConnectKeyQR                         = "screen_owner_walletconnect_qr_code"
    case connectInstalledWallet                     = "user_owner_connected_installed_wallet"
    case disconnectInstalledWallet                  = "user_owner_disconnected_installed_wallet"
    case connectExternalWallet                      = "user_owner_connected_external_wallet"
    case dappConnectedWithUniversalLink             = "user_dapp_connected_universal_link"
    case dappConnectedWithScanButton                = "user_dapp_connected_scan_button"
    case selectDapp                                 = "user_dapp_select_dapp"

    case walletConnectIncomingTransaction           = "screen_wc_incoming_transaction"
    case walletConnectEditParameters                = "screen_wc_edit_parameters"
    case advancedTxParamsOpenedHelp                 = "advanced_tx_params_opened_help"

    case ledgerKeyImported                          = "user_ledger_nano_x_key_imported"
    case ledgerSelectDevice                         = "screen_select_ledger_nano_x_device"
    case ledgerSelectKey                            = "screen_select_ledger_nano_x_key"
    case ledgerEnterKeyName                         = "screen_ledger_nano_x_enter_name"

    // MARK: Confirm transactions

    // chain_id (String): Chain id
    // source (String): one of [“tx_details”, “incoming”, “ctw”]
    // key_type (String): one of [“imported”, “generated”, “ledger_nano_x”, “connected”]
    // wallet (String?): name of the wallet (first 100 chars) for “connected” keys
    case userTransactionConfirmed                   = "user_transaction_confirmed"

    // MARK: Reject transactions

    // chain_id (String): Chain id
    // source (String) = “tx_details”
    // key_type (String): one of [“imported”, “generated”, “ledger_nano_x”, “connected”]
    // wallet (String?): name of the wallet (first 100 chars) for “connected” keys
    case userTransactionRejected                    = "user_transaction_rejected"

    // MARK: Execute transaction

    // chain_id (String): Chain id
    // source (String): one of [“tx_details”, “ctw”]
    // keyType: one of [imported, generated, wallet_connect, ledger_nano_x]
    // wallet (String?): name of the wallet (first 100 chars)
    case userTransactionExecuteSubmitted            = "user_transaction_exec_submitted"
    
    // MARK: Create Safe
    case createSafe                                 = "screen_cs"
    case createSafeIntro                            = "screen_cs_intro"
    case createSafeOnePage                          = "screen_cs_one_page"
    case createSafeSelectNetwork                    = "screen_cs_select_network"
    case createSafeSelectKey                        = "screen_cs_select_key"
    case createSafeEditTxFee                        = "screen_cs_edit_tx_fee"
    case createSafeAddDeploymentKey                 = "screen_cs_add_deployment_key"
    
    case createSafeTxFeeEdited                      = "user_cs_edit_exec_tx_fee"
    case createSafeKeyChanged                       = "user_cs_deployment_key_changed"
    case createSafeDeploymentKeyAdded               = "user_cs_deployment_key_added"
    
    case createSafeTxSubmitted                      = "user_cs_tx_submitted"
    case createSafeTxSuccedded                      = "user_cs_tx_succeded"
    case createSafeTxFailed                         = "user_cs_tx_failed"
    case createSafeRetry                            = "user_cs_retry"
    case createSafeViewTxOnEtherscan                = "user_cs_view_tx_on_etherscan"
    
    case createSafeDesktopApp                       = "user_cs_desktop_app"
    case createSafeHelpArticle                      = "user_cs_help_article"
    
    case createSafeFromOnboarding                   = "user_cs_from_onboarding"
    case addSafeFromOnboarding                      = "user_add_safe_from_onboarding"
    
    case createSafeFromSwitchSafes                  = "user_cs_from_switch_safes"
    case addSafeFromSwitchSafes                     = "user_add_safe_from_switch_safes"

    // MARK: Web Connections
    case webConnectionList                          = "screen_connect_to_web"
    case webConnectionListOpenedInfo                = "user_ctw_learn_more"

    // MARK: Web Connection Details
    case webConnectionDetails                       = "screen_ctw_connection_details"
    case webConnectionDisconnected                  = "user_ctw_disconnect"

    // MARK: Web Connection Scan QR Code
    case webConnectionQRScanner                     = "screen_ctw_scan"

    // MARK: Connection Request
    case webConnectionConnectionRequest             = "screen_ctw_select_key"
    case webConnectionConnectionRequestConfirmed    = "user_ctw_connection_confirmed"
    case webConnectionConnectionRequestRejected     = "user_ctw_connection_rejected"

    // MARK: Signature Request
    case webConnectionSignRequest                   = "screen_ctw_eth_sign"
    case webConnectionSignRequestRejected           = "user_ctw_eth_sign_rejected"

    // MARK: Send Transaction Request
    case webConnectionSendRequest                   = "screen_ctw_eth_send_tx"
    case webConnectionSendRequestRejected           = "user_ctw_eth_send_tx_rejected"

    // MARK: add delegate key
    case addDelegateKeyLedger                       = "screen_delegate_ledger_nano_x"
    case addDelegateKeyWalletConnect                = "screen_delegate_walletconnect"

    case addDelegateKeyStarted                      = "user_start_add_delegate"
    case addDelegateKeySkipped                      = "user_skip_add_delegate"
    case addDelegateKeySuccess                      = "user_success_add_delegate"
    case addDelegateKeyFailed                       = "user_failed_add_delegate"

    // MARK: delete  delegate key
    case deleteDelegateKeySuccess                   = "user_success_delete_delegate"
    case deleteDelegateKeyFailed                    = "user_failed_delete_delegate"

    // MARK: backup created keys
    case backupIntro                                = "screen_backup_intro"
    case backupSkipped                              = "user_backup_skipped"
    case backupVerifySeedPhrase                     = "screen_verify_seed_phrase"
    case backupUserCopiedSeedPhrase                 = "user_seed_phrase_copy"
    case backupUserSeedPhraseScreenshot             = "user_seed_phrase_screenshot"
    case backupConfirmSeedPhrase                    = "screen_confirm_seed_phrase"
    case backupCreatedSuccessfully                  = "screen_backup_success"
    case backupFromKeyDetails                       = "user_backup_from_key_details"
    case backupFromKeysList                         = "user_backup_from_keys_list"

    // MARK: Add Key As Owner (Add Owner)
    case addAsOwnerIntro                            = "screen_add_key_as_owner_info"
    case addAsOwnerIntroSkipped                     = "user_skip_add_key_as_owner"

    case addAsOwnerChangeConfirmations              = "screen_add_owner_change_policy"
    case addAsOwnerReview                           = "screen_add_owner_review"
    case addAsOwnerSuccess                          = "screen_add_owner_success"

    case replaceOwnerSelect                         = "screen_replace_owner_select"
    case replaceOwnerReview                         = "screen_replace_owner_review"
    case replaceOwnerSuccess                        = "screen_replace_owner_success"

    case addGenKeyAsOwner                           = "screen_add_gen_key_as_owner"
    case skipAddGenKyAsOwner                        = "user_skip_add_gen_key_as_owner"
    case addOwnerFromSettings                       = "user_add_owner_from_settings"
    case addOwnerSelectAddress                      = "screen_add_owner_select_address"
    case addOwnerSpecifyName                        = "screen_add_owner_specify_name"
    case replaceOwnerFromSettings                   = "user_replace_owner_from_settings"
    case replaceOwnerSelectNew                      = "screen_replace_owner_select_new"
    case replaceOwnerNewOwnerName                   = "screen_replace_owner_new_owner_name"

    case userRemoveOwnerFromSettings                = "user_remove_owner_from_settings"
    case removeOwnerChangePolicy                    = "screen_remove_owner_change_policy"
    case removeOwnerSuccess                         = "screen_remove_owner_success"
    case removeOwnerReview                          = "screen_remove_owner_review"

    case changeConfirmations                        = "screen_change_confirmations"
    case reviewChangeConfirmations                  = "screen_review_change_confirmations"
    case changeConfirmationsSuccess                 = "screen_change_confirmations_success"

    case screenOnboarding1                          = "screen_onboarding_1"
    case screenOnboarding2                          = "screen_onboarding_2"
    case screenOnboarding3                          = "screen_onboarding_3"
    case onboardingSkipped                          = "user_skip_onboarding"

    // Share link
    case screenAddKeyAsOwnerShareInfo               = "screen_add_key_as_owner_share_info"
    case userSkipShareLink                          = "user_skip_share_link"
    case screenAddOwnerShareLink                    = "screen_add_owner_share_link"
    case userAddOwnerShareLink                      = "user_add_owner_share_link"

    // Handle link
    case screenOwnerFromLink                        = "screen_owner_from_link"
    case userRejectOwnerFromLink                    = "user_reject_owner_from_link"
    case screenOwnerFromLinkChooseName              = "screen_owner_from_link_choose_name"
    case screenOwnerFromLinkNoKey                   = "screen_owner_from_link_no_key"
    case userOwnerFromLinkNoKeySkip                 = "user_owner_from_link_no_key_skip"
    case userOwnerFromLinkNoKeyAddIt                = "user_owner_from_link_no_key_add_it"
    case screenOwnerFromLinkNoSafe                  = "screen_owner_from_link_no_safe"
    case userOwnerFromLinkNoSafeSkip                = "user_owner_from_link_no_safe_skip"
    case screenOwnerFromLinkAddSafeName             = "screen_owner_from_link_add_safe_name"
    case userOwnerFromLinkSafeNameAdded             = "user_owner_from_link_safe_name_added "

}

extension TrackingEvent {
    static func keyTypeParameters(_ keyInfo: KeyInfo, parameters: [String: Any]? = nil) -> [String: Any] {
        var parameters = parameters ?? [String: Any]()
        parameters["key_type"] = keyInfo.keyType.trackingValue
        if keyInfo.keyType == .walletConnect {
            parameters = parametersWithWalletName(keyInfo, parameters: parameters)
        }
        return parameters
    }

    static private func parametersWithWalletName(_ keyInfo: KeyInfo, parameters: [String: Any]) -> [String: Any] {
        let connection = WebConnectionController.shared.walletConnection(keyInfo: keyInfo).first
        var walletName = connection?.remotePeer?.name ?? "Unknown"
        if walletName.count > 100 {
            walletName = String(walletName.prefix(100))
        }
        var updatedParameters = parameters
        updatedParameters["wallet"] = walletName
        return updatedParameters
    }
}

extension KeyType {
    var trackingValue: String {
        switch self {
        case .deviceGenerated:
            return "generated"
        case .deviceImported:
            return "imported"
        case .ledgerNanoX:
            return "ledger_nano_x"
        case .walletConnect:
            return "connected"
        }
    }
}
