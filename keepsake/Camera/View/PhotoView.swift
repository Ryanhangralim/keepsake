import SwiftUI
import Photos

struct PhotoView: View {
	var asset: PhotoAsset
	var cache: CachedImageManager?
	@EnvironmentObject var navigationManager: NavigationManager
	
	@State private var image: Image?
	@State private var imageRequestID: PHImageRequestID?
	@State private var isZoomed = false
	@State private var showButtonsWhenZoomed = false
	@State private var hideButtonsTimer: Timer?
	@Environment(\.dismiss) var dismiss
	@Environment(\.presentationMode) var presentationMode
	@State private var isSharing = false
	@State private var isPreparingToShare = false
	@State private var sharingItems: [Any] = []
	
	private let imageSize = CGSize(width: 1024, height: 1024)
	
	var body: some View {
		ZStack {
			VStack {
				Spacer()
				Spacer()
				Spacer()
				Spacer()
				
				Group {
					if let image = image {
						image
							.resizable()
							.scaledToFit()
							.accessibilityLabel(asset.accessibilityLabel)
							.clipShape(RoundedRectangle(cornerRadius: 14))
							.padding(20)
							.zoomable(
								onZoomChange: { zoomed in
									withAnimation(.easeInOut(duration: 0.3)) {
										isZoomed = zoomed
										if !zoomed {
											showButtonsWhenZoomed = false
											hideButtonsTimer?.invalidate()
										}
									}
								},
								onPanStart: {
									if isZoomed {
										withAnimation(.easeInOut(duration: 0.3)) {
											showButtonsWhenZoomed = false
										}
										hideButtonsTimer?.invalidate()
									}
								},
								onTap: {
									if isZoomed {
										withAnimation(.easeInOut(duration: 0.3)) {
											showButtonsWhenZoomed.toggle()
										}
										hideButtonsTimer?.invalidate()
										
										// Only set timer if buttons are now visible
										if showButtonsWhenZoomed {
											hideButtonsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
												withAnimation(.easeInOut(duration: 0.3)) {
													showButtonsWhenZoomed = false
												}
											}
										}
									}
								},
								onZoomGesture: {
									if isZoomed && showButtonsWhenZoomed {
										withAnimation(.easeInOut(duration: 0.3)) {
											showButtonsWhenZoomed = false
										}
										hideButtonsTimer?.invalidate()
									}
								}
							)
					} else {
						ProgressView()
					}
				}
				
				Spacer()
				Spacer()
				Spacer()
				Spacer()
			}
			
			// Buttons overlay - positioned absolutely to not affect layout
			VStack {
				Spacer()
				
				if !isZoomed || showButtonsWhenZoomed {
					buttonsView()
						.transition(.opacity)
				}
				
				Spacer()
					.frame(height: 40) // Bottom padding
			}
		}
		.navigationBarBackButtonHidden(true)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.ignoresSafeArea()
		.background(.black)
		.navigationBarTitleDisplayMode(.inline)
		.navigationTitle("Photo")
		.sheet(isPresented: $isSharing) {
			ActivityView(activityItems: sharingItems)
		}
		.task {
			guard image == nil, let cache = cache else { return }
			imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
				Task {
					if let result = result {
						self.image = result.image
					}
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: {
					presentationMode.wrappedValue.dismiss()
				}) {
					Image(systemName: "chevron.left")
				}
			}
		}
		.foregroundColor(.white)
		.onDisappear {
			hideButtonsTimer?.invalidate()
		}
	}
	
	private func buttonsView() -> some View {
		HStack(spacing: 60) {
			Button {
				Task {
					await sharePhoto()
				}
			} label: {
				Label("Share", systemImage: "square.and.arrow.up")
					.font(.system(size: 24))
					.opacity(isPreparingToShare ? 0 : 1)
					.overlay {
						if isPreparingToShare {
							ProgressView()
						}
					}
			}
			.disabled(isPreparingToShare)
			
			Button {
				Task {
					await asset.delete()
					await MainActor.run {
						navigationManager.path.removeLast()
					}
				}
			} label: {
				Label("Delete", systemImage: "trash")
					.font(.system(size: 24))
			}
		}
		.buttonStyle(.plain)
		.labelStyle(.iconOnly)
		.padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
		.background(Color(UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1)))
		.cornerRadius(15)
	}
	
	private func sharePhoto() async {
		await MainActor.run {
			isPreparingToShare = true
		}
		
		defer {
			Task {
				await MainActor.run { isPreparingToShare = false }
			}
		}
		
		guard let data = await fetchImageData(for: asset.phAsset) else {
			print("Failed to fetch image data for sharing.")
			return
		}
		
		guard let tempURL = saveToTemporaryDirectory(data: data) else {
			print("Failed to save photo for sharing.")
			return
		}
		
		await MainActor.run {
			sharingItems = [tempURL]
			isSharing = true
		}
	}
	
	private func fetchImageData(for phAsset: PHAsset?) async -> Data? {
		guard let asset = phAsset else { return nil }
		
		return await withCheckedContinuation { continuation in
			let options = PHImageRequestOptions()
			options.deliveryMode = .highQualityFormat
			options.isNetworkAccessAllowed = true
			
			PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
				continuation.resume(returning: data)
			}
		}
	}
	
	private func saveToTemporaryDirectory(data: Data) -> URL? {
		let tempDirectory = FileManager.default.temporaryDirectory
		let fileName = UUID().uuidString + ".jpg"
		let fileURL = tempDirectory.appendingPathComponent(fileName)
		
		do {
			try data.write(to: fileURL)
			return fileURL
		} catch {
			print("Failed to save data to temporary directory: \(error.localizedDescription)")
			return nil
		}
	}
}

struct ActivityView: UIViewControllerRepresentable {
	var activityItems: [Any]
	var applicationActivities: [UIActivity]? = nil
	
	func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
	}
	
	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
