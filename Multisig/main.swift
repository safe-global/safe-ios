//
//  main.swift
//  Multisig
//
//  Created by Vitaly Katz on 24.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

let appDelegateClass: AnyClass = NSClassFromString("TestingAppDelegate") ?? AppDelegate.self

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(appDelegateClass))
