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
}

enum TrackingPushState: String {
    case unknown, disabled, enabled
}

enum TrackingEvent: String, Trackable {
    case launch = "screen_launch"
    case launchTems = "screen_launch_terms"

    case assetsNoSafe = "screen_assets_no_safe"
    case assetsCoins = "screen_assets_coins"
    case assetsCollectibles = "screen_assets_collectibles"
    case assetsCollectiblesDetails = "screen_assets_collectibles_details"

    case safeReceive = "screen_safe_receive"
    case safeSwitch = "screen_safe_switch"
    case safeAddAddress = "screen_safe_add_address"
    case safeAddName = "screen_safe_add_name"
    case safeAddEns = "screen_safe_add_ens"

    case transactions = "screen_transactions"
    case transactionsNoSafe = "screen_transactions_no_safe"
    case transactionsDetails = "screen_transactions_details"
    case transactionsDetailsAdvanced = "screen_transactions_details_advanced"
    case transactionsDetailsAction = "transaction_details_action"

    case settingsApp = "screen_settings_app"
    case settingsAppAdvanced = "screen_settings_app_advanced"
    case settingsAppEditFiat = "screen_settings_app_edit_fiat"
    case settingsAppSupport = "screen_settings_app_support"

    case settingsSafe = "screen_settings_safe"
    case settingsSafeNoSafe = "screen_settings_safe_no_safe"
    case settingsSafeEditName = "screen_settings_safe_edit_name"
    case settingsSafeAdvanced = "screen_settings_safe_advanced"

    case camera = "screen_camera"
}
