//
//  QRCodeScanner.swift
//  Multisig
//
//  Created by Moaaz on 4/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct QRCodeScanner: UIViewControllerRepresentable {
    var header: String?
    var handler: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let scannerViewController = QRCodeScannerViewController(nibName: "QRCodeScannerViewController", bundle: nil)
        scannerViewController.delegate = context.coordinator
        scannerViewController.header = header
        scannerViewController.setup()
        
        return scannerViewController
    }
    
    func updateUIViewController(_ vc: QRCodeScannerViewController, context: Context) {
        // do nothing
    }
    
    public func qrCodeScanner(handler: @escaping (String) -> Void) -> QRCodeScanner {
        return self
    }

    class Coordinator: NSObject, QRCodeScannerViewControllerDelegate {
        func scannerViewControllerDidScan(_ code: String) {
            parent.handler(code)
        }
        
        var parent: QRCodeScanner
        
        init(_ parent: QRCodeScanner) {
            self.parent = parent
        }
    }
}

struct QRCodeScanner_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScanner() { _ in
            
        }
    }
}
