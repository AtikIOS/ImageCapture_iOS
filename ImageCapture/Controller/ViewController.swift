//
//  ViewController.swift
//  ImageCapture
//
//  Created by Atik Hasan on 2/26/25.
//

// MARK: - If  you want to check this code, you must need a real device. not support simulator
import UIKit
import CoreImage
import AVFoundation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var capturedImgView: UIImageView!{
        didSet{
            self.capturedImgView.layer.cornerRadius = capturedImgView.bounds.width / 2
        }
    }
    
    lazy private var photoOutput = AVCapturePhotoOutput()
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraPreviewView.bounds
    }
    
    private func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                } else {
                    self.dismiss(animated: true)
                }
            }
        default:
            dismiss(animated: true)
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession,
              let captureDevice = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoOrientation = .portrait  // Always Portrait
            cameraPreviewView.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    
    @IBAction func takePhotoButtonTapped(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto // Flash automatically adjusts
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnCameraSwitch(_ sender: UIButton) {
        guard let captureSession = captureSession else { return }
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }

        let newCameraPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition) else { return }
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            captureSession.beginConfiguration()
            captureSession.removeInput(currentInput)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            } else {
                captureSession.addInput(currentInput)
            }
            captureSession.commitConfiguration()
        } catch {
            print("Error switching camera: \(error)")
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        let fixedImage = fixImageOrientation(image: image)
        capturedImgView.image = fixedImage
        if fixedImage.size.width > fixedImage.size.height {
            capturedImgView.contentMode = .scaleAspectFit
        } else {
            capturedImgView.contentMode = .scaleAspectFill
        }
        print("Photo Captured: \(String(describing: fixedImage))")
    }
   

    // MARK: - Make Image Always Portrait
    func makeImageAlwaysPortrait(image: UIImage) -> UIImage {
        var newOrientation: UIImage.Orientation = .up

        switch image.imageOrientation {
        case .left, .leftMirrored:
            newOrientation = .right
        case .right, .rightMirrored:
            newOrientation = .left
        case .down, .downMirrored:
            newOrientation = .up
        default:
            newOrientation = .up
        }
        guard let cgImage = image.cgImage else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: newOrientation)
    }
    
    // MARK: - Fix Image Orientation
    func fixImageOrientation(image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let ciImage = CIImage(cgImage: cgImage)
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(orientation)
        let context = CIContext(options: nil)
        if let outputCGImage = context.createCGImage(orientedImage, from: orientedImage.extent) {
            return UIImage(cgImage: outputCGImage)
        }
        return image
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
