//
//  QRCodeScanner.swift
//  Multisig
//
//  Created by Moaaz on 4/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct QRCodeScanner: UIViewControllerRepresentable {

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

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
        var parent: QRCodeScanner
        
        init(_ parent: QRCodeScanner) {
            self.parent = parent
        }

        func scannerViewControllerDidScan(_ code: String) {
            parent.handler(code)
            close()
        }

        func scannerViewControllerDidCancel() {
            close()
        }

        func close() {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct QRCodeScanner_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScanner() { _ in
            
        }
    }
}
