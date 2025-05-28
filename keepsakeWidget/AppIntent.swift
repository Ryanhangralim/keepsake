//
//
//  AppIntent.swift
//  keepsakeWidget
//
//  Created by Agustio Maitimu on 19/05/25.
//

import WidgetKit
import AppIntents
import Photos

struct AlbumEntity: AppEntity, Equatable, Hashable {
	let id: String
	let title: String
	
	static var typeDisplayRepresentation: TypeDisplayRepresentation = "Album"
	
	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(title: LocalizedStringResource(stringLiteral: title))
	}
	
	static var defaultQuery = AlbumQuery()
}

struct AlbumQuery: EntityQuery {
	// Use shared UserDefaults to access album metadata
	private let sharedDefaults = UserDefaults(suiteName: "group.bratss.keep")
	
	func entities(for identifiers: [String]) async throws -> [AlbumEntity] {
		identifiers.compactMap { id in
			if let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject,
			   let title = collection.localizedTitle {
				let displayTitle = getDisplayTitle(for: title, albumId: id)
				return AlbumEntity(id: id, title: displayTitle)
			}
			return nil
		}
	}
	
	func suggestedEntities() async throws -> [AlbumEntity] {
		var results: [AlbumEntity] = []
		
		let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
		albums.enumerateObjects { collection, _, _ in
			if let title = collection.localizedTitle, title.hasPrefix("🌅") {
				let displayTitle = getDisplayTitle(for: title, albumId: collection.localIdentifier)
				results.append(AlbumEntity(id: collection.localIdentifier, title: displayTitle))
			}
		}
		
		return results
	}
	
	// Helper function to get display title with emoji
	private func getDisplayTitle(for originalTitle: String, albumId: String) -> String {
		let albumMetadata = loadAlbumMetadata(for: albumId)
		return originalTitle.replacingOccurrences(of: "🌅 ", with: "")
	}
	
	// Load album metadata from shared UserDefaults (same as AlbumManager)
	private func loadAlbumMetadata(for albumId: String) -> AlbumMetadata {
		guard let albumsMetadata = sharedDefaults?.dictionary(forKey: "AlbumsMetadata") as? [String: [String: Any]],
			  let metadata = albumsMetadata[albumId],
			  let emoji = metadata["emoji"] as? String else {
			return AlbumMetadata.defaultMetadata
		}
		
		return AlbumMetadata(
			emoji: emoji,
			colorHex: metadata["colorHex"] as? String ?? "#CCCCCC")
	}
}

private struct AlbumMetadata {
    let emoji: String
    let colorHex: String
    
    static let defaultMetadata = AlbumMetadata(emoji: "📷", colorHex: "#CCCCCC")
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Choose an album to display." }
    
    @Parameter(title: "Album")
    var album: AlbumEntity?
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}


