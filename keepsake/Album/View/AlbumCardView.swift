//
//  AlbumCardView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 19/05/25.
//

import SwiftUI
import Photos

struct AlbumCardView: View {
	@EnvironmentObject var albumManager: AlbumManager
	@Environment(\.colorScheme) var colorScheme
	let album: PHAssetCollection
	
	var body: some View {
		let title = album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed"
		let metadata =  albumManager.loadAlbumMetadata(for: album.localIdentifier)
		//        let color = colorScheme == .dark ? Color(hex: "#1C1C1E") : Color(hex: "#F0F0F0")
		let color = Color(hex: "#1C1C1E")
		
		if metadata.showThumbnail {
			if let thumbnail = albumManager.thumbnailCache[album.localIdentifier] {
				// Full card with thumbnail background
				ZStack {
					// Thumbnail as background
					thumbnail
						.resizable()
						.scaledToFill()
						.frame(width: 165, height: 165)
						.clipped()
					
					// Gradient overlay at bottom
					LinearGradient(
						gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
						startPoint: .bottom,
						endPoint: .top
					)
					.cornerRadius(15)
					
					// Text aligned to bottom leading
					VStack {
						Spacer()
						HStack {
							VStack(alignment: .leading, spacing: 2) {
								Text(title)
									.font(.title2)
									.fontWeight(.semibold)
									.foregroundColor(.white)
									.multilineTextAlignment(.leading)
									.lineLimit(1)
								
								Text("Tap to open camera")
									.font(.caption2)
									.fontWeight(.light)
									.foregroundStyle(.white)
							}
							.padding(.leading, 12)
							.padding(.bottom, 12)
							Spacer()
						}
					}
				}
				.frame(width: 165, height: 165)
				.background(Color(.systemBackground))
				.clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
			} else {
				DefaultAlbumCardView(title: title, color: color)
			}
		} else {
			DefaultAlbumCardView(title: title, color: color)
		}
	}
}

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
	
	// Add a method to convert Color to hex string
	func toHex() -> String {
		guard let components = UIColor(self).cgColor.components else {
			return "#000000"
		}
		
		let r = Int(components[0] * 255.0)
		let g = Int(components[1] * 255.0)
		let b = Int(components[2] * 255.0)
		
		return String(format: "#%02X%02X%02X", r, g, b)
	}
}

//#Preview {
//    AlbumCardView(title: "Vacation 2024", metadata: AlbumMetadata(emoji: "🌴", colorHex: "#FF5F6D"), model: <#DataModel#>)
//}
