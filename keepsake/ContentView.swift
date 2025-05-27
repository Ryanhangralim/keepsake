//
//  ContentView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI
import Photos
import WidgetKit

struct ContentView: View {
	static let sharedDefaults = UserDefaults(suiteName: "group.bratss.keepsake")
	@Environment(\.scenePhase) var scenePhase
	@StateObject private var albumManager = AlbumManager()
	@StateObject private var navigationManager = NavigationManager.shared
	@State private var selectedFolderIdentifier: String?
	// New Album
	@State private var showingNewAlbumAlert = false
	@State private var newAlbumName = ""
	// Rename
	@State private var showingRenameAlbumAlert = false
	@State private var renameAlbumName = ""
	@State private var contextMenuAlbum: PHAssetCollection?
	
	init() {
		_selectedFolderIdentifier = State(initialValue: Self.sharedDefaults?.string(forKey: "selectedFolder"))
	}
	
	private let columns = [
		GridItem(.flexible()),
		GridItem(.flexible())
	]
	
	var body: some View {
		NavigationStack(path: $navigationManager.path) {
			ScrollView {
				LazyVGrid(columns: columns, spacing: 15) {
					ForEach(albumManager.albums, id: \.localIdentifier) { album in
						NavigationLink(value: album) {
							AlbumCardView(album: album)
								.environmentObject(albumManager)
								.contextMenu {
									Button {
										// Rename action
										contextMenuAlbum = album
										showingRenameAlbumAlert = true
									} label: {
										Label("Rename", systemImage: "pencil")
									}
									
									Button {
										// Toggle
										albumManager.toggleAlbumThumbnail(albumId: album.localIdentifier)
									} label: {
										Label("Change Cover", systemImage: "arrow.2.squarepath")
									}
									
									Button(role: .destructive) {
										// Delete
										albumManager.deleteAlbumMetadata(for: album.localIdentifier)
										albumManager.deleteAlbum(album: album)
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
						}
					}
				}
				.padding(.horizontal)
				.padding(.top, 10)
			}
			.navigationBarTitleDisplayMode(.large)
			.navigationTitle("My Albums")
			.navigationDestination(for: PHAssetCollection.self) { album in
				CameraView(model: DataModel(album: album))
			}
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button {
						// Add new album action
						showingNewAlbumAlert = true
					} label: {
						Image(systemName: "folder.badge.plus")
							.imageScale(.large)
							.foregroundColor(.white) // Set the default text color to white
					}
				}
			}
			.onAppear {
				PHPhotoLibrary.requestAuthorization { status in
					if status == .authorized || status == .limited {
						albumManager.loadAlbums()
					}
				}
			}
			.onChange(of: scenePhase) { _, newState in
				if newState == .active {
					loadFolders()
				} else if newState == .inactive {
					WidgetCenter.shared.reloadAllTimelines()
				} else if newState == .background {
					WidgetCenter.shared.reloadAllTimelines()
				}
			}
			.onOpenURL { url in
				loadFolders()
				
				guard url.scheme == "keepsake",
					  url.host == "select-folder",
					  let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
					  let folderQuery = components.queryItems?.first(where: { $0.name == "folder" })?.value
				else {
					print("Invalid deep link: \(url)")
					return
				}
				
				if let album = getAlbum(identifier: folderQuery) {
					navigationManager.path = NavigationPath()
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						navigationManager.path.append(album)
					}
				}
			}
			.alert("New Album", isPresented: $showingNewAlbumAlert) {
				TextField("Enter new album name", text: $newAlbumName)
				HStack{
					Button("Cancel", role: .cancel) {}
					Button("Create") {
						let trimmedName = newAlbumName.trimmingCharacters(in: .whitespacesAndNewlines)
						albumManager.createAlbum(named: trimmedName) { newAlbum in
							if let album = newAlbum {
								albumManager.saveAlbumMetadata(albumId: album.localIdentifier, showThumbnail: true)
							}
						}
						newAlbumName = "" // Optional: clear text field
					}
					.disabled(newAlbumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.alert("Rename Album", isPresented: $showingRenameAlbumAlert) {
				TextField("Enter new album name", text: $renameAlbumName)
				HStack{
					Button("Cancel", role: .cancel){}
					Button("Rename"){
						let trimmedName = renameAlbumName.trimmingCharacters(in: .whitespacesAndNewlines)
						if let album = contextMenuAlbum{
							albumManager.renameAlbum(album: album, newTitle: trimmedName)
						}
						renameAlbumName = "" // Optional: clear text field
					}
					.disabled(renameAlbumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
		}
		.environmentObject(navigationManager)
		.preferredColorScheme(.dark)
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
