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
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(albumManager.albums, id: \.localIdentifier) { album in
                        NavigationLink(destination: CameraView(model: DataModel(album: album), albumManager: albumManager)) {
                            AlbumCardView(title: album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed")
//                                .frame(height: 200)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .navigationTitle("My Albums")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateAlbumView(albumManager: albumManager)) {
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
        }
    }
}
