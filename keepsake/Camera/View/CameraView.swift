//
//  CameraView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject var model: DataModel
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var isAlbumMenuVisible = false
    @StateObject var albumManager = AlbumManager()
	@State private var currentZoom = 0.0
	@State private var totalZoom = 1.0
 
    private static let barHeightFactor = 0.15
    
    var body: some View {
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
				.gesture(
					MagnifyGesture()
						.onChanged { value in
							currentZoom = value.magnification - 1
							model.camera.setZoomFactor(currentZoom)
						}
						.onEnded { value in
							totalZoom += currentZoom
							currentZoom = totalZoom
						}
				)
				.accessibilityZoomAction { action in
					if action.direction == .zoomIn {
						totalZoom += 1
					} else {
						totalZoom -= 1
					}
				}
        }
        .task {
            await model.camera.start()
            await model.loadPhotos()
            await model.loadThumbnail()
        }
        .onAppear {
            Task {
                await model.camera.start()
                await model.loadPhotos()
                await model.loadThumbnail()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
				HStack {
					albumMenu()
					Button {
						model.camera.useFlash.toggle()
					} label: {
						Image(systemName: model.camera.useFlash ? "bolt.fill" : "bolt.slash.fill")
					}
					Button {
						model.camera.setZoomFactor(5)
					} label: {
						Text("x5")
					}
					Button {
						model.camera.setZoomFactor(1)
					} label: {
						Text("x1")
					}
				}
            }
        }
        .navigationTitle(model.photoCollection.albumName?.replacingOccurrences(of: "🌅 ", with: "\(albumManager.loadAlbumMetadata(for: model.photoCollection.assetCollection?.localIdentifier ?? "📷 ").emoji) ") ?? "Camera")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PhotoCollection.self) { photoCollection in
            PhotoCollectionView(photoCollection: photoCollection)
                .onAppear {
                    model.camera.isPreviewPaused = true
                }
                .onDisappear {
                    model.camera.isPreviewPaused = false
                }
        }
        .toolbarColorScheme(.dark, for: .navigationBar) // Force dark mode for navigation bar
        .toolbarBackground(.black, for: .navigationBar) // Set navigation bar background to black
        .toolbarBackground(.visible, for: .navigationBar) // Make sure background is visible
        .foregroundColor(.white) // Set the default text color to white
        .ignoresSafeArea()
        .statusBar(hidden: true)
    }
    
    private func buttonsView() -> some View {
        HStack(spacing: 60) {
            
			Spacer()
			
            Button(action: {
                navigationManager.path.append(model.photoCollection)
            }) {
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
                    Text(album.localizedTitle?.replacingOccurrences(of: "🌅 ", with: "\(albumManager.loadAlbumMetadata(for: album.localIdentifier).emoji) ") ?? "Unnamed")
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
