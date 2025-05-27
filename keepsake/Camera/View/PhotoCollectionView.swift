//
//  PhotoCollectionView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI
import os.log

struct PhotoCollectionView: View {
	@ObservedObject var photoCollection : PhotoCollection
	@EnvironmentObject var navigationManager: NavigationManager
	@Environment(\.displayScale) private var displayScale
	@Environment(\.presentationMode) var presentationMode
	
	private static let itemSpacing = 12.0
	private static let itemCornerRadius = 15.0
	private static let itemSize = CGSize(width: 90, height: 90)
	
	private var imageSize: CGSize {
		return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
	}
	
	private let columns = [
		GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
	]
	
	var body: some View {
		ScrollView {
			LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
				ForEach(photoCollection.photoAssets) { asset in
					Button(action: {
						navigationManager.path.append(asset)
					}) {
						photoItemView(asset: asset)
					}
					.buttonStyle(.borderless)
					.accessibilityLabel(asset.accessibilityLabel)
				}
			}
			.padding([.vertical], Self.itemSpacing)
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
		.foregroundColor(.white) // Set the default text color to white
	}
	
	private func photoItemView(asset: PhotoAsset) -> some View {
		PhotoItemView(asset: asset, cache: photoCollection.cache, imageSize: imageSize)
			.frame(width: Self.itemSize.width, height: Self.itemSize.height)
			.clipped()
			.cornerRadius(Self.itemCornerRadius)
			.onAppear {
				Task {
					await photoCollection.cache.startCaching(for: [asset], targetSize: imageSize)
				}
			}
			.onDisappear {
				Task {
					await photoCollection.cache.stopCaching(for: [asset], targetSize: imageSize)
				}
			}
	}
}
