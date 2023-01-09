//
//  FrameManager.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import AVFoundation
import Vision

class FrameManager: NSObject, ObservableObject {
  static let shared = FrameManager()

  @Published var current: CVPixelBuffer?
  
  let videoOutputQueue = DispatchQueue(
    label: "app.cherrystudio.VideoOutputQ",
    qos: .userInitiated,
    attributes: [],
    autoreleaseFrequency: .workItem)

  private override init() {
    super.init()

    CameraManager.shared.set(self, queue: videoOutputQueue)
  }
}

private let handPoseRequest: VNDetectHumanHandPoseRequest = {
  let request = VNDetectHumanHandPoseRequest()
  request.maximumHandCount = 2
  return request
}()

private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()

var pointsProcessor: ((_ points: [CGPoint], _ poses: [HandPose]) -> Void)?
var bodyPointsProcessor: ((_ points: [CGPoint], _ pose: BodyPose) -> Void)?

extension FrameManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
      if let buffer = sampleBuffer.imageBuffer {
        DispatchQueue.main.async {
          self.current = buffer
        }
      }
      
      var recognizedPoints: [VNRecognizedPoint] = []
      var poses: [HandPose] = []
      
      var recognizedBodyPoints: [VNRecognizedPoint] = []
      var bodyPose = BodyPose.unsure

      func convertPoint(_ point: VNRecognizedPoint) -> CGPoint {
        let cgPoint = CGPoint(x: 1 - point.y, y: 1 - point.x)
        return CGPoint(x: 10, y: 10)//cameraPreview.previewLayer.layerPointConverted(fromCaptureDevicePoint: cgPoint)
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
        //cameraCaptureSession.stopRunning()
        print(error.localizedDescription)
      }
      
      
  }
}
