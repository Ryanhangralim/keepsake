//
//  CameraView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject var model: DataModel
    @State private var isAlbumMenuVisible = false
    @StateObject var albumManager: AlbumManager
 
    private static let barHeightFactor = 0.15
    
    var body: some View {
        
        NavigationStack {
            GeometryReader { geometry in
                ViewfinderView(image: $model.viewfinderImage)
                    .id(model.selectedAlbumID) // forces the view to reload
                    .overlay(alignment: .top) {
                        Color.clear
//                            .opacity(0.50)
                            .frame(height: geometry.size.height * Self.barHeightFactor)
                    }
                    .overlay(alignment: .bottom) {
                        buttonsView()
                            .frame(height: geometry.size.height * Self.barHeightFactor)
//                            .background(.black.opacity(0.50))
                    }
                    .overlay(alignment: .center)  {
                        Color.clear
                            .frame(height: geometry.size.height * (1 - (Self.barHeightFactor * 2)))
                            .accessibilityElement()
                            .accessibilityLabel("View Finder")
                            .accessibilityAddTraits([.isImage])
                    }
                    .background(.black)
            }
            .task {
                await model.camera.start()
                await model.loadPhotos()
                await model.loadThumbnail()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    albumMenu()
                }
            }
            .navigationTitle(model.photoCollection.albumName?.replacingOccurrences(of: "🌅 ", with: "") ?? "Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar) // Force dark mode for navigation bar
            .toolbarBackground(.black, for: .navigationBar) // Set navigation bar background to black
            .toolbarBackground(.visible, for: .navigationBar) // Make sure background is visible
            .foregroundColor(.white) // Set the default text color to white
            .ignoresSafeArea()
            .statusBar(hidden: true)
        }
    }
    
    private func buttonsView() -> some View {
        HStack(spacing: 60) {
            
            Spacer()
            
            NavigationLink {
                PhotoCollectionView(photoCollection: model.photoCollection)
                    .onAppear {
                        model.camera.isPreviewPaused = true
                    }
                    .onDisappear {
                        model.camera.isPreviewPaused = false
                    }
            } label: {
                Label {
                    Text("Gallery")
                } icon: {
                    ThumbnailView(image: model.thumbnailImage)
                }
            }
            
            Button {
                model.camera.takePhoto()
            } label: {
                Label {
                    Text("Take Photo")
                } icon: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(width: 62, height: 62)
                        Circle()
                            .fill(.white)
                            .frame(width: 50, height: 50)
                    }
                }
            }
            
            Button {
                model.camera.switchCaptureDevice()
            } label: {
                Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .padding()
    }
    
    @ViewBuilder
    private func albumMenu() -> some View {
        Menu {
            ForEach(albumManager.albums.filter { $0.localIdentifier != model.photoCollection.assetCollection?.localIdentifier }, id: \.localIdentifier) { album in
                Button(action: {
                    model.photoCollection = PhotoCollection(album: album)
                    model.selectedAlbumID = album.localIdentifier
                    Task {
                        await model.loadPhotos()
                        await model.loadThumbnail()
                    }
                }) {
                    Text(album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "") ?? "Unnamed")
                }
            }
        } label: {
            Label("Change Album", systemImage: "folder")
                .foregroundColor(.white)
        }
    }
}


//#Preview {
//    CameraView()
//}
