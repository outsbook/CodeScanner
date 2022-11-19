//
//  CodeScannerViewController.swift
//  CodeScanner
//
//  Created by Shahin Shams on 19/11/22.
//

import Foundation
import AVFoundation
import UIKit

extension CodeScannerView {
    class CodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var parentView: CodeScannerView!
        var didFinishScan = false
        var sessionId = 0
        var mySessionId = 0
        
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer!
        
        private lazy var maskView: UIImageView? = {
            guard let image = UIImage(named: "Mask", in: .module, with: nil) else {
                return nil
            }
            
            let imageView = UIImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()

        //MARK: - Init Functions
        init(parentView: CodeScannerView) {
            self.sessionId = parentView.sessionId
            self.parentView = parentView
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        override public func viewDidLoad() {
            super.viewDidLoad()
            self.addOrientationDidChangeObserver()
            view.backgroundColor = .black
            self.checkCameraPermission()
        }
        
        func updateViewController(sessionId: Int, mySessionId: Int) {
            if self.sessionId != sessionId{
                self.sessionId = sessionId
                restartSession()
            }
            if self.mySessionId != mySessionId{
                self.mySessionId = mySessionId
                restartSession()
            }
            resetTorch()
            resetFocus()
        }

        //MARK: - Override Functions
        override public func viewWillLayoutSubviews() {
            previewLayer?.frame = view.layer.bounds
        }
        
        override public func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            resetOrientation()
        }

        override public func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            setupSession()
        }
        
        override public func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            stopSession()
            NotificationCenter.default.removeObserver(self)
        }

        override public var prefersStatusBarHidden: Bool {
            true
        }

        override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            .all
        }
        
        private func addOrientationDidChangeObserver() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(resetOrientation),
                name: Notification.Name("UIDeviceOrientationDidChangeNotification"),
                object: nil
            )
        }
        
        @objc func resetOrientation() {
            guard let orientation = view.window?.windowScene?.interfaceOrientation else { return }
            guard let connection = captureSession?.connections.last, connection.isVideoOrientationSupported else { return }
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) ?? .portrait
        }
        
        public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if !parentView.isFocusOn{
                return
            }
            
            guard touches.first?.view == view,
                  let touchPoint = touches.first,
                  let device = DeviceUtil.getDevice(isBackCamera: parentView.isBackCamera),
                  device.isFocusPointOfInterestSupported
            else { return }

            let videoView = view
            let screenSize = videoView!.bounds.size
            let xPoint = touchPoint.location(in: videoView).y / screenSize.height
            let yPoint = 1.0 - touchPoint.location(in: videoView).x / screenSize.width
            let focusPoint = CGPoint(x: xPoint, y: yPoint)

            do {
                try device.lockForConfiguration()
            } catch {
                return
            }

            device.focusPointOfInterest = focusPoint
            device.focusMode = .continuousAutoFocus
            device.exposurePointOfInterest = focusPoint
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.unlockForConfiguration()
        }
        
        //MARK: - Device and Session Functions
        private func setupCaptureDevice() {
            if captureSession == nil{
                captureSession = AVCaptureSession()
            }

            guard let videoCaptureDevice = DeviceUtil.getDevice(isBackCamera: parentView.isBackCamera) else {
                return
            }

            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                onFailed(error: .initError(error))
                return
            }

            if (captureSession!.canAddInput(videoInput)) {
                captureSession!.addInput(videoInput)
            } else {
                onFailed(error: .badInputDevice)
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if (captureSession!.canAddOutput(metadataOutput)) {
                captureSession!.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = parentView.codeType
            } else {
                onFailed(error: .badMetadataOutput)
                return
            }
        }
      
        private func setupSession() {
            guard let captureSession = captureSession else {
                return
            }
            
            if previewLayer == nil {
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            }

            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            addMask()
            didFinishScan = false

            if (captureSession.isRunning == false) {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.captureSession?.startRunning()
                }
            }
        }
        
        private func addMask(){
            if !parentView.isMaskVisible{
                return
            }
            
            guard let maskView = maskView else {return }
            
            maskView.layer.opacity = 0.5
            view.addSubview(maskView)
            
            let maskSize = view.frame.width < view.frame.height ? view.frame.width * 0.75 : view.frame.height * 0.75
            
            let layoutConstraint: [NSLayoutConstraint] = [
                maskView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                maskView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                maskView.widthAnchor.constraint(equalToConstant: maskSize),
                maskView.heightAnchor.constraint(equalToConstant: maskSize)
            ]
            NSLayoutConstraint.activate(layoutConstraint)
        }
        
        private func restartSession(){
            stopSession()
            setupCaptureDevice()
            setupSession()
        }
        
        private func stopSession(){
            if (captureSession?.isRunning == true) {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.captureSession?.stopRunning()
                }
            }
            previewLayer = nil
            captureSession = nil
        }
        
        private func resetTorch(){
            if let device = DeviceUtil.getDevice(isBackCamera: parentView.isBackCamera),
               device.hasTorch
            {
                do {
                    try device.lockForConfiguration()
                } catch {
                    return
                }
                device.torchMode = parentView.isTorchOn ? .on : .off
                device.unlockForConfiguration()
            }
        }
        
        private func resetFocus(){
            let focusMode: AVCaptureDevice.FocusMode = parentView.isFocusOn ? .continuousAutoFocus : .autoFocus
            if let device = DeviceUtil.getDevice(isBackCamera: parentView.isBackCamera), device.isFocusModeSupported(focusMode){
                do {
                    try device.lockForConfiguration()
                } catch {
                    return
                }
                device.focusMode = focusMode
                device.unlockForConfiguration()
            }
        }
        
        //MARK: - Delegate Functions
        public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard didFinishScan == false else { return }
                let result = CodeScanResult(string: stringValue, type: readableObject.type)
                
                onSuccess(result)
                didFinishScan = true
            }
        }

        //MARK: - CodeScanner Callback
        func onSuccess(_ result: CodeScanResult) {
            if parentView.isVibrateOnSuccess {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            previewLayer.connection?.isEnabled = false
            parentView.onDone(.success(result))
        }

        func onFailed(error: CodeScanError) {
            if let preview = previewLayer, let con = preview.connection{
                con.isEnabled = false
            }
            parentView.onDone(.failure(error))
        }
        
        
        //MARK: - Camera Permission
        private func checkCameraPermission() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .restricted:
                    break
                case .denied:
                    self.onFailed(error: .permissionDenied)
                case .notDetermined:
                    self.requestCameraAccess {
                        self.setupCaptureDevice()
                        DispatchQueue.main.async {
                            self.setupSession()
                        }
                    }
                case .authorized:
                    self.setupCaptureDevice()
                    self.setupSession()
                    
                default:
                    break
            }
        }

        private func requestCameraAccess(onDone: (() -> Void)?) {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                guard status else {
                    self?.onFailed(error: .permissionDenied)
                    return
                }
                onDone?()
            }
        }
    }
}
