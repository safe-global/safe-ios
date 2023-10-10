//
//  File.swift
//  
//
//  Created by Dmitrii Bespalov on 10.10.23.
//

import Foundation
import SecureConfig
import Darwin

// Usage:
//
// secconfig encrypt IN_FILE OUT_FILE
//
// Tool will print the base64 encoded encryption key to a standard output and will
// take the IN_FILE, encrypt it and write to the OUT_FILE.
//
// (1) IN_FILE is a JSON file with format:
//
//      {
//        "_version": "plain-v1",
//        "config": {
//          "key1": "value1",
//          "key2": "value2"
//         }
//      }
//
// (2) OUT_FILE is a JSON file with format:
//      {
//          "_version": "sealed-v1",
//          "alg": "aes-256-gcm",
//          "text": "base64 text"
//      }
//
//
// secconfig decrypt KEY IN_FILE OUT_FILE
//
// This is an inverse operation from encrypt, i.e. it will take the
// IN_FILE with format (2) above, and decrypt it using the provided KEY
// to the file with format (1) above.
//

struct FileHandleStream: TextOutputStream {
    var handle: FileHandle
    
    func write(_ string: String) {
        let data = string.data(using: .utf8)!
        try! handle.write(contentsOf: data)
    }
}

var STDERR = FileHandleStream(handle: .standardError)
var STDOUT = FileHandleStream(handle: .standardOutput)

guard CommandLine.arguments.count >= 2 else {
    print("Too few arguments", to: &STDERR)
    exit(EXIT_FAILURE)
}

switch CommandLine.arguments[1] {
case "encrypt":
    guard CommandLine.arguments.count == 4 else {
        print("Incorrect number of arguments", to: &STDERR)
        exit(EXIT_FAILURE)
    }
    let input = CommandLine.arguments[2]
    let output = CommandLine.arguments[3]
    
    let config = SecureConfig()
    
    let file: SecureConfig.PlainFile = try config.load(filename: input)
    let sealed = try config.encrypt(file: file)
    let key = config.string(from: sealed.key)
    
    try config.save(filename: output, contents: sealed.file)
    
    print(key, to: &STDOUT)
    
    exit(EXIT_SUCCESS)
    
case "decrypt":
    guard CommandLine.arguments.count == 5 else {
        print("Incorrect number of arguments", to: &STDERR)
        exit(EXIT_FAILURE)
    }
    let keytext = CommandLine.arguments[2]
    let input = CommandLine.arguments[3]
    let output = CommandLine.arguments[4]
    
    let config = SecureConfig()
    
    guard let key = config.key(from: keytext) else {
        print("Unable to read key", to: &STDERR)
        exit(EXIT_FAILURE)
    }
    
    let file: SecureConfig.SealedFile = try config.load(filename: input)
    let plain = try config.decrypt(file: file, key: key)
    
    try config.save(filename: output, contents: plain)
    
    exit(EXIT_SUCCESS)

default:
    print("Unsupported command", to: &STDERR)
    exit(EXIT_FAILURE)
}
