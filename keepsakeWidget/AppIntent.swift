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
	func entities(for identifiers: [String]) async throws -> [AlbumEntity] {
		identifiers.compactMap { id in
			if let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil).firstObject,
			   let title = collection.localizedTitle {
				return AlbumEntity(id: id, title: title)
			}
			return nil
		}
	}
	
	func suggestedEntities() async throws -> [AlbumEntity] {
		var results: [AlbumEntity] = []
		
		let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
		albums.enumerateObjects { collection, _, _ in
			if let title = collection.localizedTitle, title.hasPrefix("🌅") {
				results.append(AlbumEntity(id: collection.localIdentifier, title: title))
			}
		}
		
		return results
	}
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


