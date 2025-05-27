//
//  ViewFinderView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI

struct ViewfinderView: View {
    @Binding var image: Image?
    
    var body: some View {
        GeometryReader { geometry in
            if let image = image {
                image
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .scaledToFit()
					.padding(30)
                    .rotationEffect(getRotationAngle())
                    .frame(width: getFrameSize(geometry).width,
                           height: getFrameSize(geometry).height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .background(.black)
            }
        }
        .background(.black)
    }
    
    private func getRotationAngle() -> Angle {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .degrees(90)
        case .landscapeRight:
            return .degrees(-90)
        case .portraitUpsideDown:
            return .degrees(180)
        default:
            return .degrees(0)
        }
    }
    
    private func getFrameSize(_ geometry: GeometryProxy) -> CGSize {
        let isLandscape = UIDevice.current.orientation.isLandscape
        if isLandscape {
            // Swap width and height for landscape
            return CGSize(width: geometry.size.height, height: geometry.size.width)
        } else {
            return geometry.size
        }
    }
}
struct ViewfinderView_Previews: PreviewProvider {
    static var previews: some View {
        ViewfinderView(image: .constant(Image(systemName: "pencil")))
    }
}
