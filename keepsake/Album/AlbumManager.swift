//
//  AlbumManager.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import Foundation
import Photos
import PhotosUI
import SwiftUICore
import SwiftUI

class AlbumManager: ObservableObject {
	@Published var albums: [PHAssetCollection] = []
	@Published var thumbnailCache: [String: Image] = [:]
	
	private let albumPrefix = "🌅 "
	private let sharedDefaults = UserDefaults(suiteName: "group.bratss.keepsake")
	private var hasLoadedAlbums = false
	
	init() {
		requestAuthorization()
	}
	
	func requestAuthorization() {
		PHPhotoLibrary.requestAuthorization { status in
			if status == .authorized || status == .limited {
				DispatchQueue.main.async {
					self.loadAlbumsIfNeeded()
				}
			}
		}
	}
	
	func loadAlbumsIfNeeded() {
		guard !hasLoadedAlbums else { return }
		hasLoadedAlbums = true
		loadAlbums()
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
			self.loadThumbnails(for: collections)
		}
	}
	
	private func loadThumbnails(for collections: [PHAssetCollection]) {
		for album in collections {
			let assets = PHAsset.fetchAssets(in: album, options: nil)
			guard let latestAsset = assets.lastObject else { continue }
			
			let manager = PHCachingImageManager()
			let targetSize = CGSize(width: 200, height: 200)
			let options = PHImageRequestOptions()
			options.deliveryMode = .highQualityFormat
			options.isSynchronous = false
			
			manager.requestImage(for: latestAsset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
				if let uiImage = image {
					DispatchQueue.main.async {
						self.thumbnailCache[album.localIdentifier] = Image(uiImage: uiImage)
					}
				}
			}
		}
	}
	
	func createAlbum(named name: String, completion: @escaping (PHAssetCollection?) -> Void) {
		let fullName = albumPrefix + name
		
		let fetchOptions = PHFetchOptions()
		fetchOptions.predicate = NSPredicate(format: "title = %@", fullName)
		let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
		
		if let existingAlbum = existing.firstObject {
			print("Album already exists.")
			completion(existingAlbum)
			return
		}
		
		var placeholder: PHObjectPlaceholder?
		
		PHPhotoLibrary.shared().performChanges({
			let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: fullName)
			placeholder = request.placeholderForCreatedAssetCollection
		}) { success, error in
			DispatchQueue.main.async {
				self.loadAlbums()
			}
			
			if success, let placeholder = placeholder {
				let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
				completion(fetchResult.firstObject)
			} else {
				print("Error creating album: \(error?.localizedDescription ?? "unknown")")
				completion(nil)
			}
		}
	}
	
	func renameAlbum(album: PHAssetCollection, newTitle: String) {
		let newName = albumPrefix + newTitle
		
		PHPhotoLibrary.shared().performChanges({
			guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
			albumChangeRequest.title = newName
		}, completionHandler: { (success, error) in
			DispatchQueue.main.async {
				self.loadAlbums()
			}
			
			if success {
				print("Album renamed successfully")
			} else if let error = error {
				print("Error renaming album: \(error.localizedDescription)")
			}
		})
	}
	
	func deleteAlbum(album: PHAssetCollection) {
		PHPhotoLibrary.shared().performChanges({
			PHAssetCollectionChangeRequest.deleteAssetCollections([album] as NSFastEnumeration)
		}, completionHandler: { (success, error) in
			DispatchQueue.main.async {
				self.loadAlbums()
			}
			
			if success {
				print("Album deleted successfully")
			} else if let error = error {
				print("Error deleting album: \(error.localizedDescription)")
			}
		})
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
	
	func saveAlbumMetadata(albumId: String, showThumbnail: Bool) {
		if var albumsMetadata = sharedDefaults?.dictionary(forKey: "AlbumsMetadata") as? [String: [String: Any]] {
			albumsMetadata[albumId] = ["showThumbnail": showThumbnail]
			sharedDefaults?.set(albumsMetadata, forKey: "AlbumsMetadata")
		} else {
			let albumsMetadata: [String: [String: Any]] = [albumId: ["showThumbnail": showThumbnail]]
			sharedDefaults?.set(albumsMetadata, forKey: "AlbumsMetadata")
		}
	}
	
	func toggleAlbumThumbnail(albumId: String) {
		var albumsMetadata = sharedDefaults?.dictionary(forKey: "AlbumsMetadata") as? [String: [String: Any]] ?? [:]
		
		// Get existing metadata for this album or create new dictionary
		var albumMetadata = albumsMetadata[albumId] ?? [:]
		
		// Fetch current showThumbnail value and toggle it (defaults to false if not set)
		let currentShowThumbnail = albumMetadata["showThumbnail"] as? Bool ?? false
		albumMetadata["showThumbnail"] = !currentShowThumbnail
		
		// Save back to the main metadata dictionary
		albumsMetadata[albumId] = albumMetadata
		sharedDefaults?.set(albumsMetadata, forKey: "AlbumsMetadata")
		
		DispatchQueue.main.async {
			self.loadAlbums()
		}
	}
	
	func loadAlbumMetadata(for albumId: String) -> AlbumMetadata {
		guard let albumsMetadata = sharedDefaults?.dictionary(forKey: "AlbumsMetadata") as? [String: [String: Any]],
			  let metadata = albumsMetadata[albumId],
			  let showThumbnail = metadata["showThumbnail"] as? Bool else {
			return AlbumMetadata.defaultMetadata
		}
		
		return AlbumMetadata(showThumbnail: showThumbnail)
	}
	
	func deleteAlbumMetadata(for albumId: String) {
		guard var albumsMetadata = sharedDefaults?.dictionary(forKey: "AlbumsMetadata") as? [String: [String: Any]] else {
			return
		}
		
		albumsMetadata.removeValue(forKey: albumId)
		sharedDefaults?.set(albumsMetadata, forKey: "AlbumsMetadata")
	}
}
