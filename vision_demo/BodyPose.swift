//
//  BodyPose.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import Vision

enum BodyPose: String {
  case unsure = ""

  // MARK: - Evaluate Body Pose
  static func evaluateBodyPose(from bodyLandmarks: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]) -> BodyPose {
    let pose: BodyPose
    
    pose = .unsure
    
    return pose
  }
}
