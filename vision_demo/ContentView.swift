//
//  ContentView.swift
//  vision_demo
//
//  Created by kai wen chen on 2022/12/27.
//

import SwiftUI

struct ContentView: View {
  @State private var overlayPoints: [CGPoint] = []
  @State private var emojiPoses: [HandPose] = []
  
  @State private var bodyPoints: [CGPoint] = []
  @State private var bodyPose = BodyPose.unsure
  
  var body: some View {
    ZStack(alignment: .top) {
      CameraView { points, poses in
        overlayPoints = points
        emojiPoses = poses
      }
      bodyPointsProcessor: { points, pose in
        bodyPoints = points
        bodyPose = pose
      }
      .overlay(
        FingersOverlay(with: overlayPoints)
          .foregroundColor(.orange)
      )
      .overlay(
        BodyOverlay(with: bodyPoints)
          .foregroundColor(.purple)
      )
      .edgesIgnoringSafeArea(.all)
      
      VStack(spacing: 20) {
        Text(concatenateEmoji(poses: emojiPoses))
          .font(.largeTitle)
        Spacer()
        Text(bodyPose.rawValue)
          .font(Font.system(size: 100))
      }
    }
  }
  
  func concatenateEmoji(poses: [HandPose]) -> String {
    poses.reduce(into: "") { string, pose in
      switch pose {
      case .unsure:
        return
      default:
        string += " " + pose.rawValue
      }
    }
  }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
