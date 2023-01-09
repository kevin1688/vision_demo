//
//  CameraViewController.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import UIKit
import AVFoundation
import Vision

final class CameraViewController: UIViewController {
  private let cameraCaptureSession = AVCaptureSession()
  private var cameraPreview: CameraPreview { view as! CameraPreview }
    
    private var bt:UIButton?
    let screenSize: CGRect = UIScreen.main.bounds

  private let videoDataOutputQueue = DispatchQueue(
    label: "CameraFeedOutput", qos: .userInteractive
  )
  
  private let handPoseRequest: VNDetectHumanHandPoseRequest = {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    return request
  }()
    @IBAction func setCamera(_ sender: Any) {
        switchCamera()
    }
    
  // TODO: - Add a body pose request
  private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
  
  var pointsProcessor: ((_ points: [CGPoint], _ poses: [HandPose]) -> Void)?
  var bodyPointsProcessor: ((_ points: [CGPoint], _ pose: BodyPose) -> Void)?
  
  override func loadView() {
      view = CameraPreview()
      bt = UIButton.init(frame: CGRect(x: screenSize.width/2-100, y: screenSize.height-100, width: 200, height: 100))
      bt?.addAction {
          self.switchCamera()
      }
      bt?.setTitle("改變鏡頭", for: .normal)
      
      view.addSubview(bt!)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupAVSession()
    setupPreview()
    cameraCaptureSession.startRunning()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    cameraCaptureSession.stopRunning()
    super.viewWillDisappear(animated)
  }
  
  func setupPreview() {
    cameraPreview.previewLayer.session = cameraCaptureSession
    cameraPreview.previewLayer.videoGravity = .resizeAspectFill
  }
  
  func setupAVSession() {
    // Start session configuration
    cameraCaptureSession.beginConfiguration()
    
    // Setup video data input
    guard
      let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
      let deviceInput = try? AVCaptureDeviceInput(device: videoDevice),
      cameraCaptureSession.canAddInput(deviceInput)
    else { return }
    
    cameraCaptureSession.sessionPreset = AVCaptureSession.Preset.high
    cameraCaptureSession.addInput(deviceInput)
    
    // Setup video data output
    let dataOutput = AVCaptureVideoDataOutput()
    guard cameraCaptureSession.canAddOutput(dataOutput)
    else { return }
    
    cameraCaptureSession.addOutput(dataOutput)
    dataOutput.alwaysDiscardsLateVideoFrames = true
    dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    
    // Commit session configuration
    cameraCaptureSession.commitConfiguration()
  }
    
    func switchCamera() {
        cameraCaptureSession.beginConfiguration()
        let currentInput = cameraCaptureSession.inputs.first as? AVCaptureDeviceInput
        cameraCaptureSession.removeInput(currentInput!)

        let newCameraDevice = currentInput?.device.position == .back ? getCamera(with: .front) : getCamera(with: .back)
        let newVideoInput = try? AVCaptureDeviceInput(device: newCameraDevice!)
        cameraCaptureSession.addInput(newVideoInput!)
        cameraCaptureSession.commitConfiguration()
    }
}

// MARK: - Private
extension CameraViewController {
    func getCamera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else {
        return nil
    }

    return devices.filter {
        $0.position == position
    }.first
}
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    var recognizedPoints: [VNRecognizedPoint] = []
    var poses: [HandPose] = []
    
    var recognizedBodyPoints: [VNRecognizedPoint] = []
    var bodyPose = BodyPose.unsure

    func convertPoint(_ point: VNRecognizedPoint) -> CGPoint {
      let cgPoint = CGPoint(x: 1 - point.y, y: 1 - point.x)
      return cameraPreview.previewLayer.layerPointConverted(fromCaptureDevicePoint: cgPoint)
    }

    defer {
      DispatchQueue.main.sync {
        let convertedPoints = recognizedPoints.map(convertPoint(_:))
        pointsProcessor?(convertedPoints, poses)
        
        let convertedBodyPoints = recognizedBodyPoints.map(convertPoint(_:))
        bodyPointsProcessor?(convertedBodyPoints, bodyPose)
      }
    }
    
    // TODO: -  Reuse this image request handler
    let handler = VNImageRequestHandler(
      cmSampleBuffer: sampleBuffer,
      orientation: .right,
      options: [:]
    )
    
    do {
      try handler.perform([handPoseRequest, bodyPoseRequest])
      
      // TODO: - Process the body pose request observations
      if let bodyPoseResults = bodyPoseRequest.results?.first {
        let armJoints: [VNHumanBodyPoseObservation.JointName] = [.leftWrist, .leftElbow, .leftShoulder, .rightShoulder, .rightElbow, .rightWrist]
        
        let armLandmarks = try bodyPoseResults.recognizedPoints(.all)
          .filter { armJoints.contains($0.key) }
          .filter { $0.value.confidence > 0.3 }
        
        bodyPose = BodyPose.evaluateBodyPose(from: armLandmarks)
        recognizedBodyPoints = Array(armLandmarks.values)
      }
      
      guard
        let results = handPoseRequest.results?.prefix(2),
        !results.isEmpty
      else { return }
      
      try results.forEach { observation in
        let handLandmarks = try observation.recognizedPoints(.all)
          .filter { point in
            point.value.confidence > 0.6
          }
        
        let tipPoints: [VNHumanHandPoseObservation.JointName] = [.thumbTip, .indexTip, .middleTip, .ringTip, .littleTip]
        let recognizedTips = tipPoints
          .compactMap { handLandmarks[$0] }
        
        recognizedPoints += recognizedTips
        
        poses.append(HandPose.evaluateHandPose(from: handLandmarks))
      }
    } catch {
      cameraCaptureSession.stopRunning()
      print(error.localizedDescription)
    }
  }
}
extension UIControl {
    func addAction(for controlEvents: UIControl.Event = .touchUpInside, _ closure: @escaping()->()) {
        @objc class ClosureSleeve: NSObject {
            let closure:()->()
            init(_ closure: @escaping()->()) { self.closure = closure }
            @objc func invoke() { closure() }
        }
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
