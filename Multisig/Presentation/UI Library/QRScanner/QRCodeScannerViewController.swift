//
//  ScannerViewController.swift
//  Multisig
//
//  Created by Moaaz on 4/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidScan(_ code: String)
}

class QRCodeScannerViewController: UIViewController {
    @IBOutlet weak var headerLabel: UILabel!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureSession: AVCaptureSession!
    var delegate: QRCodeScannerViewControllerDelegate?
    var header: String?
    
    enum Strings {
        static let cameraAlertTitle = NSLocalizedString("camera_title", comment: "")
        static let cameraAlertMessage = NSLocalizedString("camera_message", comment: "")
        static let cameraAlertCancel = NSLocalizedString("cancel", comment: "")
        static let cameraAlertAllow = NSLocalizedString("settings", comment: "")
        static let scannerNotSupportedTitle = NSLocalizedString("scanner_not_supported_title", comment: "")
        static let scannerNotSupportedMessage = NSLocalizedString("scanner_not_supported_message", comment: "")
        static let ok = NSLocalizedString("ok", comment: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        headerLabel.text = header
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    @IBAction func closeButtonTouched(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func setup() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] (result)  in
            if result {
                DispatchQueue.main.async {
                    self?.createScanner()
                }
            }
            else {
                DispatchQueue.main.async {
                    self?.presentCameraAccessRequiredAlert()
                }
            }
        }
    }

    func createScanner() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return presentFaildToCreateScannerAlert()
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            presentFaildToCreateScannerAlert()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            presentFaildToCreateScannerAlert()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)

        captureSession.startRunning()
    }
    
    private func presentCameraAccessRequiredAlert() {
        let settingsAppURL = URL(string: UIApplication.openSettingsURLString)!
        let alert = UIAlertController(
            title: Strings.cameraAlertTitle,
            message: Strings.cameraAlertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Strings.cameraAlertAllow, style: .cancel) { _ in
            UIApplication.shared.open(settingsAppURL, options: [:], completionHandler: nil)
        })
        
        alert.addAction(UIAlertAction(title: Strings.cameraAlertCancel, style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true)
    }

    func presentFaildToCreateScannerAlert() {
        let ac = UIAlertController(title: Strings.scannerNotSupportedTitle, message: Strings.scannerNotSupportedMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: Strings.ok, style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func scannerDidScan(code: String) {
        self.delegate?.scannerViewControllerDidScan(code)
        captureSession.stopRunning()
        dismiss(animated: true, completion: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let metadataObject = metadataObjects.first { (metaObject) -> Bool in
            guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return false}
            return !(readableObject.stringValue?.isEmpty ?? false) && readableObject.type == .qr
        } as? AVMetadataMachineReadableCodeObject
        
        if let metadataObject = metadataObject {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            scannerDidScan(code: metadataObject.stringValue!)
        }
    }
}
