//
//  keepsakeWidget.swift
//  keepsakeWidget
//
//  Created by Agustio Maitimu on 19/05/25.
//

import WidgetKit
import SwiftUI
import Photos

// Color hex extension for the widget
extension Color {
	init(hex: String) {
		let scanner = Scanner(string: hex)
		_ = scanner.scanString("#")
		
		var rgb: UInt64 = 0
		scanner.scanHexInt64(&rgb)
		
		let r = Double((rgb >> 16) & 0xFF) / 255
		let g = Double((rgb >> 8) & 0xFF) / 255
		let b = Double(rgb & 0xFF) / 255
		
		self.init(red: r, green: g, blue: b)
	}
}

struct Provider: AppIntentTimelineProvider {
	typealias Intent = ConfigurationAppIntent
	
	func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), albumPhoto: nil)
	}
	
	func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
		let photo = await fetchLatestPhoto(for: configuration.album?.id)
		return SimpleEntry(date: Date(), configuration: configuration, albumPhoto: photo)
	}
	
	func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
		var entries: [SimpleEntry] = []
		let currentDate = Date()
		
		let photo = await fetchLatestPhoto(for: configuration.album?.id)
		let entry = SimpleEntry(date: currentDate, configuration: configuration, albumPhoto: photo)
		entries.append(entry)
		
		// Update every hour to check for new photos
		let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
		let nextEntry = SimpleEntry(date: nextUpdate, configuration: configuration, albumPhoto: photo)
		entries.append(nextEntry)
		
		return Timeline(entries: entries, policy: .atEnd)
	}
	
	private func fetchLatestPhoto(for albumId: String?) async -> UIImage? {
		guard let albumId = albumId else { return nil }
		
		return await withCheckedContinuation { continuation in
			// Fetch the album by its identifier
			let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
			guard let album = fetchResult.firstObject else {
				continuation.resume(returning: nil)
				return
			}
			
			// Fetch assets from the album, sorted by creation date (newest first)
			let fetchOptions = PHFetchOptions()
			fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
			let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
			
			guard let latestAsset = assets.firstObject else {
				continuation.resume(returning: nil)
				return
			}
			
			// Request the image
			let manager = PHImageManager.default()
			let targetSize = CGSize(width: 200, height: 200)
			let options = PHImageRequestOptions()
			options.deliveryMode = .highQualityFormat
			options.isSynchronous = false
			options.isNetworkAccessAllowed = true
			
			manager.requestImage(for: latestAsset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, _ in
				continuation.resume(returning: image)
			}
		}
	}
}

// Updated SimpleEntry with photo fetching
struct SimpleEntry: TimelineEntry {
	let date: Date
	let configuration: ConfigurationAppIntent
	let albumPhoto: UIImage?
	
	var emoji: String {
		return getAlbumEmoji(for: configuration.album?.id)
	}
	
	var colorHex: String {
		return getAlbumColorHex(for: configuration.album?.id)
	}
	
	var showThumbnail: Bool {
		return getShowThumbnail(for: configuration.album?.id)
	}
	
	// Get album emoji from UserDefaults
	private func getAlbumEmoji(for albumId: String?) -> String {
		guard let albumId = albumId,
			  let sharedDefaults = UserDefaults(suiteName: "group.bratss.keep"),
			  let albumsMetadata = sharedDefaults.dictionary(forKey: "AlbumsMetadata") as? [String: [String: String]],
			  let metadata = albumsMetadata[albumId],
			  let emoji = metadata["emoji"] else {
			return "📷" // Default emoji
		}
		return emoji
	}
	
	// Get album color from UserDefaults
	private func getAlbumColorHex(for albumId: String?) -> String {
		guard let albumId = albumId,
			  let sharedDefaults = UserDefaults(suiteName: "group.bratss.keep"),
			  let albumsMetadata = sharedDefaults.dictionary(forKey: "AlbumsMetadata") as? [String: [String: String]],
			  let metadata = albumsMetadata[albumId],
			  let colorHex = metadata["colorHex"] else {
			return "#CCCCCC" // Default color
		}
		return colorHex
	}
	
	private func getShowThumbnail(for albumId: String?) -> Bool {
		guard let albumId = albumId,
			  let sharedDefaults = UserDefaults(suiteName: "group.bratss.keep"),
			  let albumsMetadata = sharedDefaults.dictionary(forKey: "AlbumsMetadata") as? [String: [String: Any]],
			  let metadata = albumsMetadata[albumId],
			  let showThumbnail = metadata["showThumbnail"] as? Bool else {
			return false
		}
		return showThumbnail
	}
}


struct KipsekWidgetEntryView: View {
	@Environment(\.colorScheme) var colorScheme
	var entry: Provider.Entry
	
	fileprivate func notAssignedView() -> some View {VStack(spacing: 8) {
			Text("Tap & Hold -> Edit Widget")
			.font(.caption)
			.fontWeight(.semibold)
			.foregroundColor(.white)
			.multilineTextAlignment(.leading)
		}
	}
	
	fileprivate func showThumbnailOffView(_ album: AlbumEntity, _ alert: String) -> some View {
		VStack(alignment: .center, spacing: 4) {
//			Spacer()
//			HStack {
//				VStack(alignment: .leading, spacing: 2) {
//					Text(album.title.dropFirst().dropFirst())
//						.font(.title2)
//						.fontWeight(.semibold)
//						.foregroundColor(.white)
//						.multilineTextAlignment(.leading)
//						.lineLimit(1)
//					
//					Text(alert)
//						.font(.caption2)
//						.fontWeight(.light)
//						.foregroundStyle(.white)
//				}
//				Spacer()
//			}
			
			Text(album.title)
				.font(.title2)
				.fontWeight(.semibold)
				.foregroundColor(.white)
				.multilineTextAlignment(.leading)
				.lineLimit(1)
			
			Text(alert)
				.font(.caption2)
				.fontWeight(.light)
				.foregroundStyle(.white)
		}
	}
	
	fileprivate func showThumbnailOnView(_ album: AlbumEntity) -> some View {
		if let photo = entry.albumPhoto {
			return AnyView(
				ZStack {
					Image(uiImage: photo)
						.resizable()
						.scaledToFill()
						.frame(width: 158, height: 158)
						.clipped()
					
					LinearGradient(
						gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
						startPoint: .bottom,
						endPoint: .top
					)
					.cornerRadius(15)
					
					// Semi-transparent overlay with album info
					VStack {
						Spacer()
						HStack {
							VStack(alignment: .leading, spacing: 2) {
								Text(album.title)
									.font(.title2)
									.fontWeight(.semibold)
									.foregroundColor(.white)
									.multilineTextAlignment(.leading)
									.lineLimit(1)
								
								Text("tap to open camera")
									.font(.caption2)
									.fontWeight(.light)
									.foregroundStyle(.white)
							}
							Spacer()
						}
						.padding(.leading, 14)
						.padding(.bottom, 14 )
					}
				}
			)
		} else {
			// Fall back if photo is nil
			return AnyView(showThumbnailOffView(album, "tap to open camera"))
		}
	}
	
	var body: some View {
		VStack {
			if let album = entry.configuration.album {
				if entry.showThumbnail{
					showThumbnailOnView(album)
				} else {
					showThumbnailOffView(album, "tap to open camera")
				}
			} else {
				notAssignedView()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.widgetURL(URL(string: "keepsake://select-folder?folder=\(entry.configuration.album?.id ?? "Failed")"))
		.containerBackground(for: .widget) {
			if entry.showThumbnail && entry.albumPhoto != nil {
				Color.clear.ignoresSafeArea()
			} else {
				Color(CGColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1))
			}
		}
	}
}

struct KipsekWidget: Widget {
	var body: some WidgetConfiguration {
		AppIntentConfiguration(kind: "group.bratss.keep", intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
			KipsekWidgetEntryView(entry: entry)
		}
		.configurationDisplayName("Keepsake")
		.description("Tap, Snap, Kept")
		.supportedFamilies([.systemSmall])
	}
}



//#Preview(as: .systemSmall) {
//	KipsekWidget()
//} timeline: {
//	SimpleEntry(date: .now, configuration: {
//		let intent = ConfigurationAppIntent()
//		intent.folder = "Food"
//		return intent
//	}())
//}
