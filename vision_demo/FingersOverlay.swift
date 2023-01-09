//
//  FingersOverlay.swift
//  vision_demo
//
//  Created by kai wen chen on 2023/1/9.
//

import SwiftUI

struct BodyOverlay: Shape {
  let points: [CGPoint]
  private let pointsPath = UIBezierPath()

  init(with points: [CGPoint]) {
    self.points = points
  }

  func path(in rect: CGRect) -> Path {
    for point in points {
      pointsPath.move(to: point)
      pointsPath.addArc(withCenter: point, radius: 10, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
    }
    
    return Path(pointsPath.cgPath)
  }
}

struct FingersOverlay: Shape {
  let points: [CGPoint]
  private let pointsPath = UIBezierPath()

  init(with points: [CGPoint]) {
    self.points = points
  }

  func path(in rect: CGRect) -> Path {
    for point in points {
      pointsPath.move(to: point)
      pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
    }

    return Path(pointsPath.cgPath)
  }
}

struct FingersOverlay_Previews: PreviewProvider {
  static var previews: some View {
    FingersOverlay(with: [CGPoint(x: 0, y: 100), CGPoint(x: 100, y: 100), CGPoint(x: 100, y: 0)])
  }
}
