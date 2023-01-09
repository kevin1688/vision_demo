//
//  CameraPreview.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import UIKit
import AVFoundation

final class CameraPreview: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }
}

