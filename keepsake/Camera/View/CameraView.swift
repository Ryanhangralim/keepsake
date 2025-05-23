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
	@State private var totalZoom: CGFloat = 1.0
	@State private var gestureZoom: CGFloat = 1.0
	
    private static let barHeightFactor = 0.15
    
    var body: some View {
        GeometryReader { geometry in
            ViewfinderView(image: $model.viewfinderImage)
                .id(model.selectedAlbumID) // forces the view to reload
                .overlay(alignment: .top) {
                    Color.clear
                        .frame(height: geometry.size.height * Self.barHeightFactor)
                }
                .overlay(alignment: .center)  {
                    Color.clear
                        .frame(height: geometry.size.height * (1 - (Self.barHeightFactor * 2)))
                        .accessibilityElement()
                        .accessibilityLabel("View Finder")
                        .accessibilityAddTraits([.isImage])
                }
				.overlay(alignment: .bottom) {
					buttonsView()
						.frame(height: geometry.size.height * Self.barHeightFactor)
						.padding(.bottom, 30)
				}
                .background(.black)
				.gesture(
					MagnifyGesture()
						.onChanged { value in
							gestureZoom = value.magnification
							let newZoom = totalZoom * gestureZoom
							model.camera.setZoomFactor(newZoom)
						}
						.onEnded { value in
							totalZoom *= value.magnification
							gestureZoom = 1.0
						}
				)
				.accessibilityZoomAction { action in
					let zoomStep: CGFloat = 1.2
					if action.direction == .zoomIn {
						totalZoom *= zoomStep
					} else {
						totalZoom /= zoomStep
					}
					model.camera.setZoomFactor(totalZoom)
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
	
	private func zoomSlider() -> some View {
		VStack(alignment: .leading, spacing: 4) {
			Text("Zoom: \(String(format: "%.1fx", totalZoom))")
				.font(.caption)
				.foregroundColor(.white)
			Slider(value: $totalZoom, in: 1...10, step: 0.1, onEditingChanged: { _ in
				model.camera.setZoomFactor(totalZoom)
			})
			.accentColor(.white)
		}
		.padding(.horizontal)
		.onChange(of: totalZoom) { oldValue, newValue in
			model.camera.setZoomFactor(totalZoom)
		}
	}
    
    private func buttonsView() -> some View {
		VStack {
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
