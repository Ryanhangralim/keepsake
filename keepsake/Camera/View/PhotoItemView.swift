//
//  PhotoItemView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI
import Photos

struct PhotoItemView: View {
    var asset: PhotoAsset
    var cache: CachedImageManager?
    var imageSize: Double
    
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
	@Environment(\.displayScale) private var displayScale

    var body: some View {
        
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .task {
            guard image == nil, let cache = cache else { return }
			
			// Scale target size by display scale for crisp image
			let scaledSize = CGSize(
				width: imageSize * displayScale,
				height: imageSize * displayScale
			)
			
			imageRequestID = await cache.requestImage(for: asset, targetSize: scaledSize) { result in
                Task {
                    if let result = result {
                        self.image = result.image
                    }
                }
            }
        }
    }
}
