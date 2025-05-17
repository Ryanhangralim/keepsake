//
//  AlbumManager.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import Foundation
import Photos
import PhotosUI

class AlbumManager: ObservableObject {
    @Published var albums: [PHAssetCollection] = []
    
    // Add prefix for album name
    private let albumPrefix = "🌅 "

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
            if let title = collection.localizedTitle, title.hasPrefix(self.albumPrefix) {
                collections.append(collection)
            }
        }
        
        DispatchQueue.main.async {
            self.albums = collections
        }
    }
    
    func createAlbum(named name: String) {
        let fullName = albumPrefix + name

        // Check if album already exists
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", fullName)
        let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)

        if existing.firstObject != nil {
            print("Album already exists.")
            return
        }

        PHPhotoLibrary.shared().performChanges({
            _ = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: fullName)
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
    
    func saveImage(_ image: UIImage, to album: PHAssetCollection) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let assetPlaceholder = request.placeholderForCreatedAsset,
                  let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                return
            }

            let fastEnumeration = NSArray(array: [assetPlaceholder])
            albumChangeRequest.addAssets(fastEnumeration)
        }, completionHandler: { success, error in
            if !success {
                print("Error saving image to album: \(error?.localizedDescription ?? "unknown error")")
            }
        })
    }
}
