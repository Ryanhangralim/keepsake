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
    @State private var newAlbumName: String = ""
    @State private var navigateToCamera = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    List(albumManager.albums, id: \.localIdentifier) { album in
                        NavigationLink(destination: AlbumPhotosView(album: album)) {
                            Text(album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed")
                        }
                    }
                    .navigationTitle("My Albums")
                    .navigationBarItems(trailing: NavigationLink(destination: CreateAlbumView(albumManager: albumManager)) {
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
                
                // Camera button
                NavigationLink(destination: CameraView()) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
