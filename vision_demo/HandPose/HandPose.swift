//
//  HandPose.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import Vision

enum HandPose: String {
  case five = "Five 👋"
  case metal = "Rock On 🤘"
  case peace = "Peace ✌️"
  case callMe = "Call Me 🤙"
  case thumbsUp = "Thumbs Up 👍"
  case pointing = "Pointing ☝️"
  case fist = "Fist ✊"
  case unsure
  
  // MARK: - Evaluate Hand Pose
  static func evaluateHandPose(from handLandmarks: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) -> HandPose {
    guard handLandmarks[.wrist] != nil else { return .unsure }
    
    switch Finger.getExtendedFingers(from: handLandmarks) {
    case Set(Finger.allCases): return .five
    case [.index, .little]: return .metal
    case [.index, .middle]: return .peace
    case [.thumb, .little]: return .callMe
    case [.thumb]: return .thumbsUp
    case [.index]: return .pointing
    case []: return .fist
    default: return .unsure
    }
  }
}

