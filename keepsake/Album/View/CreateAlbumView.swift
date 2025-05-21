//
//  CreateAlbumView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI

struct CreateAlbumView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var albumManager: AlbumManager
    @State private var albumName: String = ""
    @State private var selectedEmoji: String = "📷"
    @State private var selectedColor: Color = .blue
    @State private var showEmojiPicker = false
    
    // Common emojis for albums
    private let emojis = ["📷", "🖼️", "🏞️", "👨‍👩‍👧‍👦", "🎉", "🎂", "🏖️", "✈️", "🏠", "🐶", "🎵", "🎮", "📚", "💼", "🏆"]
    
    var body: some View {
        Form {
            Section(header: Text("Album Name")) {
                TextField("Enter name", text: $albumName)
            }
            
            Section(header: Text("Select Emoji")) {
                Picker("Emoji", selection: $selectedEmoji) {
                    ForEach(emojis, id: \.self) { emoji in
                        Text(emoji).tag(emoji)
                    }
                }
            }
            
            Section(header: Text("Album Color")) {
                ColorPicker("Choose a color", selection: $selectedColor)
            }
            
            Section {
                Button("Create Album") {
                    let trimmedName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
                    albumManager.createAlbum(named: trimmedName) { newAlbum in
                        if let album = newAlbum {
                            albumManager.saveAlbumMetadata(albumId: album.localIdentifier, emoji: selectedEmoji, color: selectedColor)
                        }
                    }
                    navigationManager.path.removeLast()
                    presentationMode.wrappedValue.dismiss()

                }
                .disabled(albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("New Album")
    }
}
