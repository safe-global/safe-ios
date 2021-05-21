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
    case passcodeIsSet = "passcode_is_set" // string, "true" or "false" depending on if app passcode is set
}

extension Tracker {
    func setSafeCount(_ count: Int) {
        setUserProperty("\(count)", for: TrackingUserProperty.numSafes)
    }

    func setPushInfo(_ status: String) {
        setUserProperty(status, for: TrackingUserProperty.pushInfo)
    }

    func setNumKeysImported(_ count: Int) {
        setUserProperty("\(count)", for: TrackingUserProperty.numKeysImported)
    }

    func setPasscodeIsSet(to status: Bool) {
        let property = status ? "true" : "false"
        setUserProperty(property, for: TrackingUserProperty.passcodeIsSet)
    }
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

    case safeReceive                                = "screen_safe_receive"
    case safeSwitch                                 = "screen_safe_switch"
    case safeAddAddress                             = "screen_safe_add_address"
    case safeAddName                                = "screen_safe_add_name"
    case safeAddEns                                 = "screen_safe_add_ens"
    case safeAddUd                                  = "screen_safe_add_ud"

    case transactionsQueued                         = "screen_transactions_queue"
    case transactionsHistory                        = "screen_transactions_history"
    case transactionsNoSafe                         = "screen_transactions_no_safe"
    case transactionsDetails                        = "screen_transactions_details"
    case transactionDetailsRejectionConfirmation    = "screen_transactions_reject_confirmation"

    case transactionsDetailsAdvanced                = "screen_transactions_details_advanced"
    case transactionsDetailsAction                  = "screen_transaction_details_action"
    case transactionDetailsActionList               = "screen_transaction_details_action_list"
    case transactionDetailsTransactionConfirmed     = "user_transaction_confirmed"
    case transactionDetailsTransactionRejected      = "user_transaction_rejected"

    case settingsApp                                = "screen_settings_app"
    case settingsAppAdvanced                        = "screen_settings_app_advanced"
    case settingsAppEditFiat                        = "screen_settings_app_edit_fiat"
    case settingsAppSupport                         = "screen_settings_app_support"

    case settingsSafe                               = "screen_settings_safe"
    case settingsSafeNoSafe                         = "screen_settings_safe_no_safe"
    case settingsSafeEditName                       = "screen_settings_safe_edit_name"
    case settingsSafeAdvanced                       = "screen_settings_safe_advanced"

    case appUpdateDeprecated                        = "screen_update_deprecated"
    case appUpdateDeprecatedSoon                    = "screen_update_deprecated_soon"
    case appUpdateOptional                          = "screen_update_new_version"

    case userOnboardingOwnerSkip                    = "user_onboarding_owner_skip"
    case userOnboardingOwnerImport                  = "user_onboarding_owner_import"
    case ownerKeysList                              = "screen_owner_list"
    case editOwnerKey                               = "screen_owner_edit_name"
    case importOwnerOnboarding                      = "screen_owner_info"
    case ownerEnterSeed                             = "screen_owner_enter_seed"
    case ownerConfirmPrivateKey                     = "screen_owner_confirm_private_key"
    case ownerSelectAccount                         = "screen_owner_select_account"
    case enterKeyName                               = "screen_owner_enter_name"
    case ownerKeyImported                           = "user_key_imported"
    case ownerKeyRemoved                            = "user_key_deleted"
    case chooseOwner                                = "screen_owner_choose"
    case bannerImportOwnerKeySkipped                = "user_banner_owner_skip"
    case bannerImportOwnerKeyImported               = "user_banner_owner_import"
    case camera                                     = "screen_camera"

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
}
