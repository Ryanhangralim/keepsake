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
    @State private var selectedColor: String = "#FF5F6D"
    @State private var showEmojiPicker = false

    private let availableEmojis = ["📷", "🖼️", "🏞️", "👨‍👩‍👧‍👦", "🎉", "🎂", "🏖️", "✈️", "🏠", "🐶", "🎵", "🎮", "📚", "💼", "🏆"]
    
    let availableColors: [String] = ["#FF5F6D", "#FFC371", "#2193B0", "#4E54C8", "#757F9A", "#56AB2F", "#F8B500", "#FF9A9E", "#355C7D", "#A18CD1"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 16)
                
                AlbumCardView(
                    title: albumName.isEmpty ? "Album Name" : albumName,
                    metadata: AlbumMetadata(emoji: selectedEmoji, colorHex: selectedColor)
                )
                
                // Name field
                Text("Album Name")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                TextField("Album Name", text: $albumName)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                // Emoji field
                Text("Customize Emoji")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableEmojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(UIColor.systemGray6))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedEmoji == emoji ? Color(UIColor.systemGray4) : Color.clear, lineWidth: 2)
                                        )

                                    Text(emoji)
                                        .font(.system(size: 24)) // Adjust size as needed
                                }
                                .padding(.vertical, 1)
                            }
                        }

                    }
                    .padding(.horizontal)
                }
                
                // Color field
                Text("Customize Color")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            Button {
                                selectedColor = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorHex ? Color.secondary : Color.clear, lineWidth: 2)
                                    )
                                    .padding(.vertical, 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Spacer between text field and button
                Spacer().frame(height: 12)
                
                Button("Create") {
                    let trimmedName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
                    albumManager.createAlbum(named: trimmedName) { newAlbum in
                        if let album = newAlbum {
                            albumManager.saveAlbumMetadata(albumId: album.localIdentifier, emoji: selectedEmoji, hexColor: selectedColor)
                        }
                    }
                    navigationManager.path.removeLast()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: .infinity)
                .padding()
                .background(albumName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer().frame(height: 24)
            }
        }
        .navigationTitle("Create New Album")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let mockAlbumManager = AlbumManager()
    let mockNavigationManager = NavigationManager()

    return NavigationStack {
        CreateAlbumView(albumManager: mockAlbumManager)
            .environmentObject(mockNavigationManager)
    }
}
