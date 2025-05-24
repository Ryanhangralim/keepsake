//
//  AlbumMetadata.swift
//  keepsake
//
//  Created by Ryan Hangralim on 20/05/25.
//

import Foundation

struct AlbumMetadata: Codable {
	let showThumbnail: Bool
	
	
	static let defaultMetadata = AlbumMetadata(showThumbnail: true)
}
