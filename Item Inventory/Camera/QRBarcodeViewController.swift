//
//  QRViewController.swift
//  Item Inventory
//
//  Created by Przemek Ambroży on 01/05/2021.
//

import UIKit
import AVFoundation
import SwiftUI

protocol QRViewControllerDelegate: AnyObject {
    func qrCode(code: String)
    func error()
}

class QRBarcodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var session: AVCaptureSession?
    var preview: AVCaptureVideoPreviewLayer?

    weak var delegate: QRViewControllerDelegate?
    var objectTypes: [AVMetadataObject.ObjectType] = [.qr]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let session = session, !session.isRunning {
            session.startRunning()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        checkAuthorization()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let session = session, session.isRunning {
            session.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        if
            let object = metadataObjects.first,
            let readable = object as? AVMetadataMachineReadableCodeObject,
            let value = readable.stringValue {


            if let session = session, session.isRunning {
                session.stopRunning()
            }

            dismiss(animated: true, completion: nil)
            delegate?.qrCode(code: value)

        }

    }

    private func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setup()
                } else {
                    self?.errorAlert("No camera access")
                }
            }
        case .restricted:
            errorAlert("Camera usage restricted")
        case .denied:
            errorAlert("No camera access")
        case .authorized:
            setup()
        @unknown default:
            errorAlert("Unknown camera access state")
        }
    }

    private func setup() {

        let session = AVCaptureSession()
        self.session = session

        // Video input

        guard
            let device = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: device)
        else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            errorAlert("Cannot scan code")
            return
        }

        // Metadata output

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = objectTypes
        } else {
            errorAlert("Cannot scan code")
            return
        }

        // Preview

        preview = AVCaptureVideoPreviewLayer(session: session)
        preview?.frame = view.layer.bounds
        preview?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview!)


        session.startRunning()
    }

    private func errorAlert(_ text: String) {
        let alert = UIAlertController(title: "Error",
                                      message: text,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            self?.delegate?.error()
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
        session = nil
    }

    override var prefersStatusBarHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

}

struct QRBarcodeView: UIViewControllerRepresentable {

    typealias Handler = (Result) -> ()

    enum Result {
        case success(String)
        case error
    }

    enum ObjectType  {
        case qr
        case ean8
        case ean13
        case upc

        fileprivate var avMetadataObject: AVMetadataObject.ObjectType {
            switch self {
            case .qr:
                return .qr
            case .ean8:
                return .ean8
            case .ean13:
                return .ean13
            case .upc:
                return .upce
            }
        }
    }

    class Coordinator: QRViewControllerDelegate {

        var handler: Handler

        init(handler: @escaping Handler) {
            self.handler = handler
        }

        func qrCode(code: String) {
            handler(.success(code))
        }

        func error() {
            handler(.error)
        }

    }

    private let handler: Handler
    private let objectTypes: [AVMetadataObject.ObjectType]

    init(objectTypes: [ObjectType], handler: @escaping Handler) {
        self.handler = handler
        self.objectTypes = objectTypes.map { $0.avMetadataObject }
    }

    func makeUIViewController(context: Context) -> QRBarcodeViewController {
        let controller = QRBarcodeViewController()
        controller.delegate = context.coordinator
        controller.objectTypes = objectTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: QRBarcodeViewController, context: Context) {
        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(handler: handler)
    }

}
