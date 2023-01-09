//
//  Finger.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import CoreGraphics
import simd
import Vision

enum Finger: Hashable, CaseIterable {
  case index, middle, ring, little, thumb
  
  static func thumbExtends(
    tip: VNRecognizedPoint?, ip: VNRecognizedPoint?,
    mp: VNRecognizedPoint?, cmc: VNRecognizedPoint?,
    indexMCP: VNRecognizedPoint?
  ) -> Bool {
    guard let tip = tip,
          let ip = ip,
          let mp = mp,
          let cmc = cmc,
          let indexMCP = indexMCP
    else { return false }
    
    let thumbIndexDotProduct = normalizedDotProduct(origin: mp.location, joints: (tip.location, indexMCP.location))
    
    return
      thumbIndexDotProduct < 0.65
      && tip.distance(cmc) > ip.distance(cmc)
      && ip.distance(cmc) > mp.distance(cmc)
  }
  
  static func extends(tip: VNRecognizedPoint?, pip: VNRecognizedPoint?, wrist: VNRecognizedPoint) -> Bool {
    guard let tip = tip,
          let pip = pip
    else { return false }
    
    return tip.distance(wrist) > pip.distance(wrist)
  }
  
  static func getExtendedFingers(from handLandmarks: [VNHumanHandPoseObservation.JointName : VNRecognizedPoint]) -> Set<Finger> {
    guard let wrist = handLandmarks[.wrist] else { return [] }
    
    let fingers = Finger.allCases.filter { finger in
      switch finger {
      case .index:
        return extends(tip: handLandmarks[.indexTip], pip: handLandmarks[.indexPIP], wrist: wrist)
      case .middle:
        return extends(tip: handLandmarks[.middleTip], pip: handLandmarks[.middlePIP], wrist: wrist)
      case .ring:
        return extends(tip: handLandmarks[.ringTip], pip: handLandmarks[.ringPIP], wrist: wrist)
      case .little:
        return extends(tip: handLandmarks[.littleTip], pip: handLandmarks[.littlePIP], wrist: wrist)
      case .thumb:
        return thumbExtends(tip: handLandmarks[.thumbTip], ip: handLandmarks[.thumbIP], mp: handLandmarks[.thumbMP], cmc: handLandmarks[.thumbCMC], indexMCP: handLandmarks[.indexMCP])
      }
    }
    
    return Set(fingers)
  }
}


// MARK: - Extensions
func normalizedDotProduct(origin: CGPoint, joints: (CGPoint, CGPoint)) -> Double {
  let origin = SIMD2(origin)
  return dot(
    normalize(SIMD2(joints.0) - origin),
    normalize(SIMD2(joints.1) - origin)
  )
}

extension SIMD2 where Scalar == CGFloat.NativeType {
  init(_ point: CGPoint) {
    self.init(x: point.x.native, y: point.y.native)
  }
}
