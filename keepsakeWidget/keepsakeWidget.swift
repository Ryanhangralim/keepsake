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
		SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
	}
	
	func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
		SimpleEntry(date: Date(), configuration: configuration)
	}
	
	func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
		var entries: [SimpleEntry] = []
		let currentDate = Date()
		let entry = SimpleEntry(date: currentDate, configuration: configuration)
		entries.append(entry)
		
		return Timeline(entries: entries, policy: .never)
	}
}

struct SimpleEntry: TimelineEntry {
	let date: Date
	let configuration: ConfigurationAppIntent
	
	// Define metadata directly in SimpleEntry
	var emoji: String {
		return getAlbumEmoji(for: configuration.album?.id)
	}
	
	var colorHex: String {
		return getAlbumColorHex(for: configuration.album?.id)
	}
	
	// Get album emoji from UserDefaults
	private func getAlbumEmoji(for albumId: String?) -> String {
		guard let albumId = albumId,
			  let sharedDefaults = UserDefaults(suiteName: "group.bratss.keepsake"),
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
			  let sharedDefaults = UserDefaults(suiteName: "group.bratss.keepsake"),
			  let albumsMetadata = sharedDefaults.dictionary(forKey: "AlbumsMetadata") as? [String: [String: String]],
			  let metadata = albumsMetadata[albumId],
			  let colorHex = metadata["colorHex"] else {
			return "#CCCCCC" // Default color
		}
		return colorHex
	}
}

struct KipsekWidgetEntryView: View {
	@Environment(\.colorScheme) var colorScheme
	var entry: Provider.Entry
	
	var body: some View {
		// Main content
		VStack {
			if let album = entry.configuration.album {
				VStack(spacing: 8) {
					Text(entry.emoji)
						.font(.system(size: 36))
					
					Text(String(album.title.dropFirst()))
						.font(.headline)
						.foregroundColor(.primary)
				}
			} else {
				VStack(spacing: 8) {
					Text("📸")
						.font(.system(size: 36))
					
					Text("Tap & Hold -> Edit Widget")
						.font(.caption)
						.foregroundColor(.primary)
				}
			}
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.widgetURL(URL(string: "keepsake://select-folder?folder=\(entry.configuration.album?.id ?? "Failed")"))
		// Use the containerBackground modifier to set the color for the entire widget
		.containerBackground(for: .widget) {
			Color(hex: entry.colorHex)
				.ignoresSafeArea()
		}
	}
}

struct KipsekWidget: Widget {
	var body: some WidgetConfiguration {
		AppIntentConfiguration(kind: "group.bratss.keepsake", intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
			KipsekWidgetEntryView(entry: entry)
		}
		.configurationDisplayName("Kipsek")
		.description("Auto-Sorter Camera")
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
