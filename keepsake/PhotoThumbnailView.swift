//
//  PhotoThumbnailView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
    // Fixed size for thumbnails
    private let thumbnailSize: CGFloat = 100
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .frame(width: thumbnailSize, height: thumbnailSize)
            }
        }
        .frame(width: thumbnailSize, height: thumbnailSize) // Explicitly set frame size
        .onAppear {
            loadThumbnail()
        }
    }
    
    func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat // Changed to high quality
        options.resizeMode = .exact // Use exact for better sizing
        options.isSynchronous = false
        
        // Request image at the exact size we need
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: thumbnailSize * UIScreen.main.scale,
                              height: thumbnailSize * UIScreen.main.scale),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result = result {
                image = result
            }
        }
    }
}

