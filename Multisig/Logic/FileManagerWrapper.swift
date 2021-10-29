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
        do {
            try text.write(to: exportFileURL, atomically: true, encoding: String.Encoding.utf8)
            return exportFileURL
        } catch {
            App.shared.snackbar.show(error: GSError.FileManagerError())
        }

        return nil
    }

    static func importFile(url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: String.Encoding.utf8)
        } catch {
            App.shared.snackbar.show(error: GSError.FileManagerError())
        }

        return nil
    }
}
