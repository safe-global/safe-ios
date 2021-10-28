//
//  FileManager.swift
//  Multisig
//
//  Created by Moaaz on 10/26/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class FileManagerWrapper {
    static func export(text: String, fileName: String, fileExtension: String) -> URL? {
        let exportFilePath = NSTemporaryDirectory() + "\(fileName).\(fileExtension)"
        let exportFileURL = URL(fileURLWithPath: exportFilePath)
        FileManager.default.createFile(atPath: exportFilePath, contents: NSData() as Data, attributes: nil)
        do {
            let fileHandle = try FileHandle(forWritingTo: exportFileURL)
            fileHandle.seekToEndOfFile()
            let csvData = text.data(using: String.Encoding.utf8, allowLossyConversion: false)
            fileHandle.write(csvData!)
            fileHandle.closeFile()
            return URL(fileURLWithPath: exportFilePath)
        } catch {
            App.shared.snackbar.show(error: GSError.FileManagerError())
        }

        return nil
    }

    static func importFile(url: URL) -> String? {
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            var text: String?
            if let data = try fileHandle.readToEnd() {
                text = String(data: data, encoding: .utf8)
            }

            fileHandle.closeFile()
            return text
        } catch {
            App.shared.snackbar.show(error: GSError.FileManagerError())
        }

        return nil
    }
}
