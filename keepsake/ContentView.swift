//
//  ContentView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI
import Photos

struct ContentView: View {
	static let sharedDefaults = UserDefaults(suiteName: "group.com.brat.keepsake")
	@Environment(\.scenePhase) var scenePhase
	@StateObject private var albumManager = AlbumManager()
	@StateObject private var navigationManager = NavigationManager.shared
	@State private var selectedFolderIdentifier: String? 
	
	init() {
		_selectedFolderIdentifier = State(initialValue: Self.sharedDefaults?.string(forKey: "selectedFolder"))
	}
	
	var body: some View {
		NavigationStack(path: $navigationManager.path) {
			VStack {
				Text(getAlbumName(identifier: selectedFolderIdentifier ?? "No Folder Selected"))
				
				List(albumManager.albums, id: \.localIdentifier) { album in
					NavigationLink(
						value: album
					) {
						Text(album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed")
					}
				}
				.navigationTitle("My Albums")
				.navigationDestination(for: PHAssetCollection.self) { album in
					CameraView(model: DataModel(album: album))
				}
				.navigationDestination(for: String.self) { destination in
					if destination == "CreateAlbum" {
						CreateAlbumView(albumManager: albumManager)
					}
				}
				.navigationBarItems(trailing:
										Button(action: {
					navigationManager.path.append("CreateAlbum")
				}) {
					Image(systemName: "plus")
						.imageScale(.large)
				}
				)
				.onAppear {
					PHPhotoLibrary.requestAuthorization { status in
						if status == .authorized || status == .limited {
							albumManager.loadAlbums()
						}
					}
				}
				.onChange(of: scenePhase) { oldState, newState in
					if newState == .active {
						loadFolders()
					}
				}
				.onOpenURL { url in
					// Update selectedFolderIdentifier when a deep link is received
					loadFolders()
					if let album = getAlbum(identifier: selectedFolderIdentifier) {
						navigationManager.path = NavigationPath()
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							navigationManager.path.append(album)
						}
					}
				}
			}
		}
		.environmentObject(navigationManager)
	}
	
	private func loadFolders() {
		selectedFolderIdentifier = Self.sharedDefaults?.string(forKey: "selectedFolder")
	}
	
	private func getAlbum(identifier: String?) -> PHAssetCollection? {
		guard let identifier = identifier else { return nil }
		return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil).firstObject
	}
	
	private func getAlbumName(identifier: String?) -> String {
		guard let identifier = identifier else { return "No Folder Selected" }
		let userAlbums = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
		return userAlbums.firstObject?.localizedTitle ?? "No Folder Selected"
	}
}
