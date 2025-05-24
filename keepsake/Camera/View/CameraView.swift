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
	@Environment(\.presentationMode) var presentationMode
	@State private var isAlbumMenuVisible = false
	@StateObject var albumManager = AlbumManager()
	@State private var totalZoom: CGFloat = 1.0
	@State private var gestureZoom: CGFloat = 1.0
	@State private var wideZoomLevel: CGFloat = 1
	@State private var ultraWideZoomLevel: CGFloat = 0.5
	@State private var isUltraWideActive: Bool = false
	
	var body: some View {
		VStack {
			ViewfinderView(image: $model.viewfinderImage)
				.id(model.selectedAlbumID) // forces the view to reload
				.accessibilityElement()
				.accessibilityLabel("View Finder")
				.accessibilityAddTraits([.isImage])
				.gesture(
					MagnifyGesture()
						.onChanged { value in
							gestureZoom = value.magnification
							if isUltraWideActive {
								// On ultrawide, allow zoom from 0.5x to 0.9x
								let newZoom = clamp(totalZoom * gestureZoom, min: 0.5, max: 0.9)
								// Convert UI zoom (0.5-0.9) to device zoom (1.0-1.8)
								let deviceZoom = newZoom * 2.0
								model.camera.setZoomFactor(deviceZoom)
								ultraWideZoomLevel = newZoom
							} else {
								// On wide camera, allow 1.0x to 10.0x zoom
								let newZoom = clamp(totalZoom * gestureZoom, min: 1.0, max: 10.0)
								model.camera.setZoomFactor(newZoom)
								wideZoomLevel = newZoom
							}
						}
						.onEnded { value in
							if isUltraWideActive {
								let newZoom = clamp(totalZoom * value.magnification, min: 0.5, max: 0.9)
								totalZoom = newZoom
								ultraWideZoomLevel = newZoom
							} else {
								let newZoom = clamp(totalZoom * value.magnification, min: 1.0, max: 10.0)
								totalZoom = newZoom
								wideZoomLevel = newZoom
							}
							gestureZoom = 1.0
						}
				)
				.accessibilityZoomAction { action in
					let zoomStep: CGFloat = 1.2
					if isUltraWideActive {
						// Allow zoom on ultrawide camera (0.5x to 0.9x)
						if action.direction == .zoomIn {
							totalZoom = clamp(totalZoom * zoomStep, min: 0.5, max: 0.9)
						} else {
							totalZoom = clamp(totalZoom / zoomStep, min: 0.5, max: 0.9)
						}
						// Convert UI zoom to device zoom
						let deviceZoom = totalZoom * 2.0
						model.camera.setZoomFactor(deviceZoom)
						ultraWideZoomLevel = totalZoom
					} else {
						// Wide camera zoom
						if action.direction == .zoomIn {
							totalZoom = clamp(totalZoom * zoomStep, min: 1.0, max: 10.0)
						} else {
							totalZoom = clamp(totalZoom / zoomStep, min: 1.0, max: 10.0)
						}
						model.camera.setZoomFactor(totalZoom)
						wideZoomLevel = totalZoom
					}
				}
			
			Spacer()
			
			buttonsView()
		}
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
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
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: {
					presentationMode.wrappedValue.dismiss()
				}) {
					Image(systemName: "xmark")
				}
			}
		}
		.navigationTitle(model.photoCollection.albumName?.replacingOccurrences(of: "🌅 ", with: "") ?? "Camera")
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
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				HStack {
					albumMenu()
				}
			}
		}
		.foregroundColor(.white) // Set the default text color to white
		.statusBar(hidden: true)
		.background(.black)
	}
	
	private func buttonsView() -> some View {
		VStack(spacing: 30) {
			HStack(alignment: .center, spacing: 10) {
				Spacer()
				Spacer()
				
				HStack(spacing: 12) {
					Button("\(String(format: "%.1f", ultraWideZoomLevel))x") {
						switchToUltraWide()
					}
					.font(.system(size: isUltraWideActive ? 14 : 10))
					.bold()
					.frame(width: isUltraWideActive ? 39 : 31, height: isUltraWideActive ? 39 : 31)
					.background(isUltraWideActive ? Color(red: 248/255, green: 215/255, blue: 74/255).opacity(0.3) : Color.white.opacity(0.1))
					.clipShape(RoundedRectangle(cornerRadius: 999))
					.foregroundStyle(isUltraWideActive ? Color(red: 248/255, green: 215/255, blue: 74/255) : Color.white)
					
					Button("\(String(format: "%.1f", wideZoomLevel).replacingOccurrences(of: ".0", with: ""))x") {
						switchToWide()
					}
					.font(.system(size: !isUltraWideActive ? 14 : 10))
					.bold()
					.frame(width: !isUltraWideActive ? 39 : 31, height: !isUltraWideActive ? 39 : 31)
					.background(!isUltraWideActive ? Color(red: 248/255, green: 215/255, blue: 74/255).opacity(0.3) : Color.white.opacity(0.1))
					.clipShape(RoundedRectangle(cornerRadius: 999))
					.foregroundStyle(!isUltraWideActive ? Color(red: 248/255, green: 215/255, blue: 74/255) : Color.white)
				}
				.padding(6)
				.background(Color.white.opacity(0.075))
				.clipShape(Capsule())
				
				Spacer()
				
				Button {
					model.camera.useFlash.toggle()
				} label: {
					Image(systemName: model.camera.useFlash ? "bolt.fill" : "bolt.slash.fill")
				}
				.font(.title)
				
				Spacer()
				Spacer()
			}
			
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
								.frame(width: 70, height: 70)
							Circle()
								.fill(.white)
								.frame(width: 58, height: 58)
						}
					}
				}
				
				Button {
					model.camera.switchCaptureDevice()
				} label: {
					Label("Switch Camera", systemImage: "arrow.triangle.2.circlepath")
						.font(.system(size: 33, weight: .bold))
						.foregroundColor(.white)
				}
				
				Spacer()
			}
			.buttonStyle(.plain)
			.labelStyle(.iconOnly)
		}
		.padding(.bottom, 28)
		.background(.black)
	}
	
	private func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
		return min(max(value, minValue), maxValue)
	}
	
	private func switchToUltraWide() {
		// Switch to ultrawide camera with current zoom level
		model.camera.switchToUltraWideWithZoom(ultraWideZoomLevel)
		totalZoom = ultraWideZoomLevel
		isUltraWideActive = true
	}
	
	private func switchToWide() {
		// Switch to wide camera with current zoom level
		let targetZoom = totalZoom < 1.0 ? 1.0 : wideZoomLevel
		model.camera.switchToWideWithZoom(targetZoom)
		totalZoom = targetZoom
		wideZoomLevel = targetZoom
		isUltraWideActive = false
	}
	
	private func updateZoomLevels(for zoom: CGFloat) {
		if zoom < 1.0 {
			ultraWideZoomLevel = clamp(zoom, min: 0.5, max: 0.9)
		} else {
			wideZoomLevel = clamp(zoom, min: 1.0, max: 10.0)
		}
	}
	
	private func updateActiveZoomMode(for zoom: CGFloat) {
		isUltraWideActive = zoom < 1.0
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
			Label("Change Album", systemImage: "list.bullet")
				.foregroundColor(.white)
		}
	}
}

extension Color {
	public static let darkGray = Color(red: 48/255, green: 48/255, blue: 48/255)
}
