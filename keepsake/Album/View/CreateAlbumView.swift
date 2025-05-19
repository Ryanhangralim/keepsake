//
//  CreateAlbumView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI

struct CreateAlbumView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var albumManager: AlbumManager
    @State private var albumName: String = ""

    var body: some View {
        Form {
            Section(header: Text("Album Name")) {
                TextField("Enter name", text: $albumName)
            }

            Section {
                Button("Create Album") {
                    let trimmedName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty else { return }
                    albumManager.createAlbum(named: trimmedName)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("New Album")
    }
}
