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
    func scannerViewControllerDidCancel()
}

class QRCodeScannerViewController: UIViewController {
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var cameraFrameView: UIImageView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureSession: AVCaptureSession!
    var delegate: QRCodeScannerViewControllerDelegate?
    var label: String?
    var attributedLabel: NSAttributedString?
    var scannedValueValidator: ((String) -> Result<String, Error>)?
    var trackingParameters: [String: Any]?

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
        if let attributedLabel = attributedLabel {
            footerLabel.attributedText = attributedLabel
        } else {
            footerLabel.text = label
            footerLabel.setStyle(.headline.color(.white))
        }
        view.bringSubviewToFront(cameraFrameView)

        NotificationCenter.default.addObserver(self, selector: #selector(handleVideoInterruption(notification:)), name: .AVCaptureSessionWasInterrupted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruptionEnd(notification:)), name: .AVCaptureSessionInterruptionEnded, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }

        Tracker.trackEvent(.camera, parameters: trackingParameters)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        correctVideoOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    @objc private func handleVideoInterruption(notification: Notification) {
        let alert = UIAlertController(title: "Camera unavailable", message: "The camera is unavailable in Split View or in Slide Over mode. Please open the app to full screen.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }

    @objc private func handleInterruptionEnd(notification: Notification) {
        if presentedViewController != nil {
            dismiss(animated: true)
        }
        correctVideoOrientation()
    }

    func correctVideoOrientation() {
        guard let previewLayer = previewLayer else { return }
        // We have to rotate the preview layer to the current interface orientation because it always starts
        // in the 'portrait' orientation.
        switch self.view.window?.windowScene?.interfaceOrientation {
        case .portrait:
            previewLayer.transform = CATransform3DMakeRotation(0, 0, 0, 1)
        case .portraitUpsideDown:
            previewLayer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
        case .landscapeLeft:
            previewLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        case .landscapeRight:
            previewLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        default:
            break
        }

        previewLayer.frame = view.layer.bounds
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let layer = previewLayer {
            // Rotate the preview layer to the new orientation.
            // NOTE: to understand what transformation matrices are and how to rotate coordinates,
            // see https://www.youtube.com/watch?v=kYB8IZa5AuE

            // convert from Core Graphics 2D transform matrix to Core Animation 3D transform matrix
            let newOrientation = CATransform3DMakeAffineTransform(coordinator.targetTransform)
            // Apply transformation (rotation to new orientation) to the current transform matrix
            let currentInterfaceRotatedToNewOrientation = CATransform3DConcat(newOrientation, layer.transform)
            // Somehow camera appears to be flipped by 180 degrees after rotation, so rotate it back
            let flippedBy180Degrees = CATransform3DRotate(currentInterfaceRotatedToNewOrientation, -CGFloat.pi, 0, 0, 1)
            layer.transform = flippedBy180Degrees
        }
    }

    @IBAction func closeButtonTouched(_ sender: Any) {
        delegate?.scannerViewControllerDidCancel()
    }
    
    func setup() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] (result)  in
            if result {
                DispatchQueue.main.async {
                    self?.createScanner()
                }
            } else {
                DispatchQueue.main.async {
                    self?.presentCameraAccessRequiredAlert()
                }
            }
        }
    }

    func createScanner() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            presentFailedToCreateScannerAlert()
            return
        }

        captureSession = AVCaptureSession()
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            presentFailedToCreateScannerAlert()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            presentFailedToCreateScannerAlert()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)

        DispatchQueue.global().async { [weak self] in
            self?.captureSession.startRunning()
        }
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
            self?.delegate?.scannerViewControllerDidCancel()
        })
        present(alert, animated: true)
    }

    func presentFailedToCreateScannerAlert() {
        let ac = UIAlertController(title: Strings.scannerNotSupportedTitle,
                                   message: Strings.scannerNotSupportedMessage,
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: Strings.ok, style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func scannerDidScan(code: String) {
        captureSession.stopRunning()
        delegate?.scannerViewControllerDidScan(code)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        let scannedValue = metadataObjects
            .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
            .filter { $0.type == .qr }
            .compactMap { $0.stringValue }
            .filter { !$0.isEmpty }
            .first

        guard let code = scannedValue else { return }

        guard let validator = scannedValueValidator else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            scannerDidScan(code: code)
            return
        }

        switch validator(code) {
        case .success(let validatedCode):
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            scannerDidScan(code: validatedCode)
        case .failure(let error):
            captureSession.stopRunning()
            let alert = UIAlertController(title: "Error",
                                          message: error.localizedDescription,
                                          preferredStyle: .alert)
            let retryButton = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                self?.captureSession.startRunning()
            }
            alert.addAction(retryButton)
            present(alert, animated: true)
        }
    }
}


