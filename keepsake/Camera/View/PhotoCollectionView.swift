//
//  PhotoCollectionView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI
import os.log

struct PhotoCollectionView: View {
	@ObservedObject var photoCollection: PhotoCollection
	@EnvironmentObject var navigationManager: NavigationManager
	@Environment(\.displayScale) private var displayScale
	@Environment(\.presentationMode) var presentationMode
	
	private static let spacing: CGFloat = 12
	private static let itemCornerRadius: CGFloat = 8
	private static let columns: Int = 3
	
	private var imageSize: CGFloat {
		let screenWidth = UIScreen.main.bounds.width
		let totalSpacing = Self.spacing * CGFloat(Self.columns + 1)
		return (screenWidth - totalSpacing) / CGFloat(Self.columns)
	}
	
	var body: some View {
		ScrollView {
			LazyVGrid(
				columns: Array(repeating: GridItem(.flexible(), spacing: Self.spacing), count: Self.columns),
				spacing: Self.spacing
			) {
				ForEach(photoCollection.photoAssets) { asset in
					Button(action: {
						navigationManager.path.append(asset)
					}) {
						PhotoItemView(
							asset: asset,
							cache: photoCollection.cache,
							imageSize: imageSize
						)
						.frame(width: imageSize, height: imageSize)
						.cornerRadius(Self.itemCornerRadius)
						.clipped()
					}
					.buttonStyle(.borderless)
					.accessibilityLabel(asset.accessibilityLabel)
				}
			}
			.padding(.all, Self.spacing)
		}
		.navigationBarTitleDisplayMode(.inline)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: {
					presentationMode.wrappedValue.dismiss()
				}) {
					Image(systemName: "chevron.left")
				}
			}
		}
		.navigationTitle(photoCollection.albumName?.replacingOccurrences(of: "🌅 ", with: "") ?? "Gallery")
		.navigationDestination(for: PhotoAsset.self) { asset in
			PhotoView(asset: asset, cache: photoCollection.cache)
		}
		.statusBar(hidden: false)
		.foregroundColor(.white)
	}
}
