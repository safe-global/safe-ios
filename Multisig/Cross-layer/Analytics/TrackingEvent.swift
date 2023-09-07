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
    case numKeysKeystone = "num_keys_keystone" // string, number of Keystone keys, "0" on fresh install
    case numKeysWeb3AuthApple = "num_keys_web3auth_apple" // string, number of Web3Auth keys of Apple login, "0" on fresh install
    case numKeysWeb3AuthGoogle = "num_keys_web3auth_google" // string, number of Web3Auth keys of Goolge login, "0" on fresh install
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
    case chooseHardwareWallet                       = "screen_choose_hardware_wallet"
    case creatingSocialKey                          = "screen_creating_social_key"
    case chooseSocialAccountType                    = "screen_choose_combined"

    case importOwnerOnboarding                      = "screen_owner_info"
    case generateOwnerOnboarding                    = "screen_owner_generate_info"
    case connectOwnerOnboarding                     = "screen_owner_walletconnect_info"
    case ledgerOwnerOnboarding                      = "screen_owner_ledger_nano_x_info"
    case keystoneOwnerOnboarding                    = "screen_owner_keystone_info"

    case ownerEnterSeed                             = "screen_owner_enter_seed"
    case ownerConfirmPrivateKey                     = "screen_owner_confirm_private_key"
    case ownerSelectAccount                         = "screen_owner_select_account"
    case enterKeyName                               = "screen_owner_enter_name"

    case ownerKeyImported                           = "user_key_imported"
    case ownerKeyGenerated                          = "user_key_generated"
    case web3AuthKeyApple                           = "user_web3auth_key_Apple"
    case web3AuthKeyGoogle                          = "user_web3auth_key_Google"
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

    case keystoneQRScanner                          = "screen_keystone_scan"
    case keystoneKeyImported                        = "user_keystone_key_imported"

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
    case successTxSigner                            = "screen_tx_signer_success"
    case successTxRelay                             = "screen_tx_relay_success"
    
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
    
    case addSafeFromURL                             = "user_add_safe_from_url"
    case createSafeFromURL                          = "user_create_safe_from_url"

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
    case screen_add_delegate                        = "screen_add_delegate"
    
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
    case userOwnerFromLinkSafeNameAdded             = "user_owner_from_link_safe_name_added"

    // MARK: Gelato Relay
    case bannerRelaySkip                            = "user_banner_relay_skip"
    case bannerRelayOpen                            = "user_banner_relay_open"
    case relayOnboarding1                           = "screen_onboarding_relay_1"
    case relayOnboarding2                           = "screen_onboarding_relay_2"
    case relayOnboarding3                           = "screen_onboarding_relay_3"
    case relayOnboarding4                           = "screen_onboarding_relay_4"
    case relayChoosePayment                         = "screen_exec_tx_payment"
    case relayUserExecTxPaymentRelay                = "user_exec_tx_payment_relay"
    case relayUserExecTxPaymentSigner               = "user_exec_tx_payment_signer"
    // successful submission to the relay service
    case relayUserSuccess                           = "user_relay_success"
    // failed submission to the relay service
    case relayUserFailure                           = "user_relay_failure"

    
    // MARK: Safe Token Claim
    // See: https://docs.google.com/spreadsheets/d/1mj9iQIhpM-Pak7lQMb1dmxhQn1QdJoJyhbc730dZNzA/edit#gid=1949479240&range=A244:E244
    // Banner Tracking
    case bannerSafeTokenClaim                       = "user_banner_safe_token_claim"
    case bannerSafeTokenSkip                        = "user_banner_safe_token_skip"
    case userClaimOpen                              = "user_claim_open"

    // Welcome screen Tracking
    case screenClaimWelcome                         = "screen_claim_welcome"
    case userClaimStart                             = "user_claim_start"

    // What is Safe? screen Tracking
    case screenClaimWhatis                          = "screen_claim_whatis"
    case userClaimWhatisNext                        = "user_claim_whatis_next"

    // Distribution screen Tracking
    case screenClaimDistr                           = "screen_claim_distr"
    case userClaimDistrDetails                      = "user_claim_distr_details"
    case userClaimDistrNext                         = "user_claim_distr_next"

    // Distribution Details Tracking
    case screenClaimDistrDetail                     = "screen_claim_distr_detail"

    // What is safe token? screen Tracking
    case screenClaimGov                             = "screen_claim_gov"
    case userClaimGovProto                          = "user_claim_gov_proto"
    case userClaimGovInterface                      = "user_claim_gov_interface"
    case userClaimGovAssets                         = "user_claim_gov_assets"
    case userClaimGovToken                          = "user_claim_gov_token"
    case userClaimGovNext                           = "user_claim_gov_next"

    // Navigating SafeDAO screen Tracking
    case screenClaimDao                             = "screen_claim_dao"
    case userClaimDaoStart                          = "user_claim_dao_start"

    // Legal disclaimer screen Tracking
    case screenClaimLegal                           = "screen_claim_legal"
    case userClaimLegalAgree                        = "user_claim_legal_agree"

    // Choose a delegate screen Tracking
    case screenClaimChdel                           = "screen_claim_chdel"
    case userClaimChdelGuard                        = "user_claim_chdel_guard"
    case userClaimChdelAddr                         = "user_claim_chdel_addr"
    case userClaimChdelSearch                       = "user_claim_chdel_search"
    case screenClaimChdelNf                         = "screen_claim_chdel_nf"

    // Custom address screen Tracking
    case screenClaimAddr                            = "screen_claim_addr"
    case userClaimAddrSelect                        = "user_claim_addr_select"

    // Delegate details screen Tracking
    case screenClaimDeldet                          = "screen_claim_deldet"
    case userClaimDeldetSelect                      = "user_claim_deldet_select"

    // Claiming form screen Tracking
    case screenClaimForm                            = "screen_claim_form"
    case userClaimFormFutTp                         = "user_claim_form_fut_tp"
    case userClaimFormMax                           = "user_claim_form_max"
    case userClaimFormPart                          = "user_claim_form_part"
    case userClaimFormDel                           = "user_claim_form_del"
    case userClaimFormClaim                         = "user_claim_form_claim"
    case userClaimFormReload                        = "user_claim_form_reload"

    // Review claiming transaction screen Tracking
    case screenClaimReview                          = "screen_claim_review"
    case userClaimReviewConfirm                     = "user_claim_review_confirm"
    case userClaimReviewAct                         = "user_claim_review_act"
    case userClaimReviewPar                         = "user_claim_review_par"

    // Claiming transaction success screen Tracking
    case screenClaimSuccess                         = "screen_claim_success"
    case userClaimSuccessTweet                      = "user_claim_success_tweet"
    case userClaimSuccessClose                      = "user_claim_success_close"
    case userClaimSuccessDone                       = "user_claim_success_done"
    case userClaimSuccessShare                      = "user_claim_success_share"

    // Claiming not eligible screen Tracking
    case screenClaimNot                             = "screen_claim_not"
    case userClaimNotDao                            = "user_claim_not_dao"
    case userClaimNotForum                          = "user_claim_not_forum"
    case userClaimNotOk                             = "user_claim_not_ok"

    // MARK: Web2 style onboarding
    case screenStartingInfo                        = "screen_starting_screen_info"
    case screenSocialLoginInfo                     = "screen_info_modal_sheet"
    case screenCreatingInProgress                  = "screen_creating_in_progress"
    case screenCreatingComplete                    = "screen_creating_complete"

    case userHowItWorks                            = "user_how_does_it_work"
    case userContinueGoogle                        = "user_continue_google"
    case userContinueApple                         = "user_continue_apple"
    case userContinueAddress                       = "user_use_wallet_address"
    case userReadMore                              = "user_read_more"
    case userCreatingCompleteContinue              = "user_creating_complete_continue"
    case userLearnMore                             = "user_learn_more"
    case userAddOwner                              = "user_add_owner"

    // Onramping

    case userBuy                                   = "user_buying"
    case userBuyCrypto                             = "user_buying_crypto"
    case userTopUpEOA                              = "user_top_EOA"
    case userTopUpSafeAccount                      = "user_top_safe_account"
    case screenSelectTopUpAddress                  = "screen_select_top_up_address"

    // MFA

    case screenSecurityOverview                    = "screen_security_overview"
    case screenEmailAddress                        = "screen_email_address"
    case securityOverviewInfo                      = "user_click_info_security_overview"
    case screenStartCreatePassword                 = "screen_set_pw_start"
    case screenCreatePassword                      = "screen_set_pw_create"
    case screenCreatePasswordSuccess               = "screen_set_pw_sucess"
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
        case .keystone:
            return "keystone"
        case .web3AuthApple:
            return "web3AuthApple"
        case .web3AuthGoogle:
            return "web3AuthGoogle"
        }
    }
}
