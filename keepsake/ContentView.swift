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

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("New album name", text: $newAlbumName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button("Create") {
                        let trimmedName = newAlbumName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        albumManager.createAlbum(named: trimmedName)
                        newAlbumName = ""
                    }
                    .padding(.trailing)
                }
                .padding(.top)
                
                NavigationView {
                    List(albumManager.albums, id: \.localIdentifier) { album in
                        NavigationLink(destination: AlbumPhotosView(album: album)) {
                            Text(album.localizedTitle?.replacingOccurrences(of: "\u{200B}", with: "") ?? "Unnamed")
                        }
                    }
                    .navigationTitle("My Albums")
                    .onAppear {
                        PHPhotoLibrary.requestAuthorization { status in
                            if status == .authorized || status == .limited {
                                albumManager.loadAlbums()
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Albums")
        }
    }
}

#Preview {
    ContentView()
}
