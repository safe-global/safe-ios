//
//  main.swift
//  
//
//  Created by Dmitry Bespalov on 05.01.22.
//

// Generates swift abi types from the safe deployment.

import Foundation
import SafeDeployments

func printUsage() {
    print("Usage: \(URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent) safe CONTRACT_ID VERSION | potato abi FILENAME")
}

let args = Array(CommandLine.arguments.dropFirst())

guard args.count == 2 else {
    printUsage()
    exit(EXIT_FAILURE)
}

guard let contract = Safe.ContractId(rawValue: args[0]) else {
    print("invalid CONTRACT_ID")
    printUsage()
    exit(EXIT_FAILURE)
}

guard let version = Safe.Version(rawValue: args[1]) else {
    print("invalid VERSION")
    printUsage()
    exit(EXIT_FAILURE)
}

do {
    guard let contract = try Safe.Deployment.find(contract: contract, version: version) else {
        print("Safe deployment not found")
        exit(EXIT_FAILURE)
    }

    let generator = Generator(contract: contract, contractNameSuffix: "_" + version.identifier)
    let output = generator.generate()
    print(output)

} catch {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}


// potato safe gnosis_safe v1.1.1 > SafeAbi/GnosisSafe_v1_1_1.swift

// potato abi <filename.json> > SafeClaimingAbi/DelegateRegistry.swift
