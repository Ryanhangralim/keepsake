//
//  PhotoAsset.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import Photos
import os.log

struct PhotoAsset: Identifiable {
	var id: String { identifier }
	var identifier: String = UUID().uuidString
	var index: Int?
	var phAsset: PHAsset?
	
	typealias MediaType = PHAssetMediaType
	
	var mediaType: MediaType {
		phAsset?.mediaType ?? .unknown
	}
	
	var accessibilityLabel: String {
		"Photo"
	}
	
	init(phAsset: PHAsset, index: Int?) {
		self.phAsset = phAsset
		self.index = index
		self.identifier = phAsset.localIdentifier
	}
	
	init(identifier: String) {
		self.identifier = identifier
		let fetchedAssets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
		self.phAsset = fetchedAssets.firstObject
	}
	
	func delete() async {
		guard let phAsset = phAsset else { return }
		do {
			try await PHPhotoLibrary.shared().performChanges {
				PHAssetChangeRequest.deleteAssets([phAsset] as NSArray)
			}
			logger.debug("PhotoAsset asset deleted: \(index ?? -1)")
		} catch (let error) {
			logger.error("Failed to delete photo: \(error.localizedDescription)")
		}
	}
}

extension PhotoAsset: Equatable {
	static func ==(lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
		lhs.identifier == rhs.identifier
	}
}

extension PhotoAsset: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
	}
}

extension PHObject: Identifiable {
	public var id: String { localIdentifier }
}

fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "PhotoAsset")
