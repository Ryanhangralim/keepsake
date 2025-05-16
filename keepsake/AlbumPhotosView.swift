//
//  AlbumPhotosView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI
import Photos

struct AlbumPhotosView: View {
    let album: PHAssetCollection
    @State private var assets: [PHAsset] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 4)
                ],
                spacing: 4
            ) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(asset: asset)
                        .padding(2) // Small padding around each thumbnail
                }
            }
            .padding(4)
        }
        .navigationTitle(album.localizedTitle ?? "Album")
        .onAppear(perform: loadPhotos)
    }
    
    func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: fetchOptions)
        var tempAssets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            tempAssets.append(asset)
        }
        self.assets = tempAssets
    }
}

//#Preview {
//    AlbumPhotosView()
//}
