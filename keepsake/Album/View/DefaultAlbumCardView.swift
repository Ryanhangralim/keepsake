//
//  DefaultAlbumCardView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 24/05/25.
//

import SwiftUI

struct DefaultAlbumCardView: View {
	let title: String
	let color: Color
	
	var body: some View {
		ZStack {
			Rectangle()
				.fill(Color(hex: "#161616"))
				.frame(width: 165, height: 165)
				.cornerRadius(15)
			
			VStack(alignment: .center, spacing: 2) {
//				Text(title)
//					.font(.title)
//					.fontWeight(.bold)
//					.foregroundColor(.white)
//					.multilineTextAlignment(.center)
//					.lineLimit(1)
//				
//				Text("Tap to open camera")
//					.font(.caption2)
//					.fontWeight(.light)
//					.foregroundColor(.white)
				
				Text(title)
					.font(.system(size: 26))
					.fontWeight(.heavy)
					.multilineTextAlignment(.leading)
					.lineLimit(1)
				Text("Tap to open camera")
					.font(.system(size: 8))
					.fontWeight(.light)
			}
			.padding(30)
			.foregroundStyle(.white)
			.multilineTextAlignment(.center)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.overlay {
				HStack {
					Spacer()
					VStack {
						Image(uiImage: UIImage(named: "transparentIcon") ?? UIImage())
							.resizable()
							.frame(width: 28, height: 28)
						Spacer()
					}
				}
				.padding()
			}
		}
	}
}

#Preview {
	DefaultAlbumCardView(title: "test", color: .gray)
}
