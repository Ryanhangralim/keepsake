//
//  ContentView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    static let sharedDefaults = UserDefaults(suiteName: "group.com.keepsakeu")
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var albumManager = AlbumManager()
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var selectedFolderIdentifier: String?
    
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
                            AlbumCardView(
                                title: album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed",
                                metadata: albumManager.loadAlbumMetadata(for: album.localIdentifier)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationManager.path = NavigationPath()
                        navigationManager.path.append("CreateAlbum")
                    } label: {
                        Image(systemName: "plus")
                            .imageScale(.large)
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
