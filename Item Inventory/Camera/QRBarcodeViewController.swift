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
    func code(_ code: String, _ type: AVMetadataObject.ObjectType)
    func error()
}

class QRBarcodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var session: AVCaptureSession?
    var preview: AVCaptureVideoPreviewLayer?

    /// Whether the capture session showld be running
    var isActive: Bool = true {
        didSet {
            if finishedSetup, let session = session, !session.isRunning, isActive {
                session.startRunning()
            } else if let session = session, session.isRunning, !isActive {
                session.stopRunning()
            }
        }
    }
    var objectTypes: [AVMetadataObject.ObjectType] = [.qr]
    weak var delegate: QRViewControllerDelegate?

    private var startedSetup = false
    private var finishedSetup = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // If we have authorization - start now
        if case .authorized = AVCaptureDevice.authorizationStatus(for: .video) {
            setup()
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if finishedSetup, let session = session, !session.isRunning, isActive {
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

            isActive = false

            delegate?.code(value, object.type)
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

        if startedSetup { return }
        startedSetup = true

        DispatchQueue.global(qos: .userInteractive).async {

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
                DispatchQueue.main.async {
                    self.errorAlert("Cannot scan code")
                }
                return
            }

            // Metadata output

            let metadataOutput = AVCaptureMetadataOutput()

            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
                metadataOutput.metadataObjectTypes = self.objectTypes
            } else {
                DispatchQueue.main.async {
                    self.errorAlert("Cannot scan code")
                }
                return
            }

            session.commitConfiguration()
            session.startRunning()

            // Preview
            DispatchQueue.main.async {
                self.preview = AVCaptureVideoPreviewLayer(session: session)
                self.preview?.frame = self.view.layer.bounds
                self.preview?.videoGravity = .resizeAspectFill
                self.view.layer.addSublayer(self.preview!)

                self.finishedSetup = true
            }


        }

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

    @Binding var active: Bool

    enum Result {
        case success(String, ObjectType)
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

        init?(_ from: AVMetadataObject.ObjectType) {
            switch from {
            case .qr:
                self = .qr
            case .ean8:
                self = .ean8
            case .ean13:
                self = .ean13
            case .upce:
                self = .upc
            default:
                return nil
            }
        }
    }

    class Coordinator: QRViewControllerDelegate {

        var handler: Handler

        init(handler: @escaping Handler) {
            self.handler = handler
        }

        func code(_ code: String, _ type: AVMetadataObject.ObjectType) {
            if let type = ObjectType(type) {
                handler(.success(code, type))
            }
        }

        func error() {
            handler(.error)
        }

    }

    private let handler: Handler
    private let objectTypes: [AVMetadataObject.ObjectType]

    init(objectTypes: [ObjectType], active: Binding<Bool>? = nil, handler: @escaping Handler) {
        self.handler = handler
        self.objectTypes = objectTypes.map { $0.avMetadataObject }
        self._active = active ?? .constant(true)
    }

    func makeUIViewController(context: Context) -> QRBarcodeViewController {
        let controller = QRBarcodeViewController()
        controller.delegate = context.coordinator
        controller.objectTypes = objectTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: QRBarcodeViewController, context: Context) {
        uiViewController.isActive = active
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(handler: handler)
    }

}

struct QRBarcodeClosableView: View {

    @Environment(\.presentationMode)
    private var presentationMode

    let objectTypes: [QRBarcodeView.ObjectType]
    let handler: QRBarcodeView.Handler

    @State private var result: QRBarcodeView.Result?

    var body: some View {
        ZStack {
            QRBarcodeView(objectTypes: objectTypes, handler: handle(_:))
                .edgesIgnoringSafeArea(.all)
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Close")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(16.0)
                    .background(
                        RoundedRectangle(cornerRadius: 32.0, style: .continuous)
                            .fill(Color.blue)
                            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 0)
                    )
                    .padding([.horizontal, .bottom], 16.0)
                    .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 0)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .onDisappear {
            if let result = result {
                handler(result)
            }
        }
    }

    private func handle(_ result: QRBarcodeView.Result) {
        self.result = result
        presentationMode.wrappedValue.dismiss()
    }
}
