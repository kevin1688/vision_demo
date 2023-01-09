//
//  CameraView.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
  var pointsProcessor: ((_ points: [CGPoint], _ poses: [HandPose]) -> Void)?
  var bodyPointsProcessor: ((_ points: [CGPoint], _ pose: BodyPose) -> Void)?
  
  func makeUIViewController(context: Context) -> CameraViewController {
      print("nix")
    let cameraViewController = CameraViewController(nibName: "cv", bundle: nil)
    cameraViewController.pointsProcessor = pointsProcessor
    cameraViewController.bodyPointsProcessor = bodyPointsProcessor
    return cameraViewController
  }

  func updateUIViewController(
    _ uiViewController: CameraViewController,
    context: Context
  ) {
  }
}

