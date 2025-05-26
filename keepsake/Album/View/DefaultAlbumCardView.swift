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
				.fill(color)
				.frame(width: 165, height: 165)
				.cornerRadius(15)
			
			VStack(alignment: .center, spacing: 4) {
				Text(title)
					.font(.title)
					.fontWeight(.bold)
					.foregroundColor(.white)
					.multilineTextAlignment(.center)
					.lineLimit(1)
				
				Text("tap to open camera")
					.font(.caption2)
					.fontWeight(.light)
					.foregroundColor(.white)
			}
			.multilineTextAlignment(.center)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
}

#Preview {
	DefaultAlbumCardView(title: "test", color: .gray)
}
