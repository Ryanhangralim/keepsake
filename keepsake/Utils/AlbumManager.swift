//
//  AlbumManager.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import Foundation
import Photos

class AlbumManager: ObservableObject {
    @Published var albums: [PHAssetCollection] = []

    init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    self.loadAlbums()
                }
            }
        }
    }

    func loadAlbums() {
        var collections: [PHAssetCollection] = []
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            collections.append(collection)
        }
        self.albums = collections
    }

    func createAlbum(named name: String) {
        PHPhotoLibrary.shared().performChanges({
            _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.loadAlbums()
                }
            } else {
                print("Error creating album: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
}
