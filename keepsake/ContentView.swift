//
//  ContentView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var albumManager = AlbumManager()

    var body: some View {
        NavigationStack {
            List(albumManager.albums, id: \.localIdentifier) { album in
                NavigationLink(destination: CameraView(model: DataModel(album: album))) {
                    Text(album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed")
                }
            }
            .navigationTitle("My Albums")
            .navigationBarItems(trailing:
                NavigationLink(destination: CreateAlbumView(albumManager: albumManager)) {
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
        }
    }
}
