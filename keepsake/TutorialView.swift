//
//  ContentView.swift
//  keepsake
//
//  Created by Agustio Maitimu on 16/05/25.
//

import SwiftUI
import Photos

struct TutorialView: View {
	@State private var currentPage = 0
	static let sharedDefaults = UserDefaults(suiteName: "group.bratss.keepsake")
	@StateObject private var navigationManager = NavigationManager.shared
	@State private var selectedFolderIdentifier: String?
	
	let onComplete: () -> Void
	
	let pages = [
		OnboardingPage(title: "Add Widget", description: "Add the Keepsake widget to your Home Screen to easily capture."),
		OnboardingPage(title: "Add Widget", description: "Long press anywhere on your Home Screen until apps jiggle, then tap the 'Edit' button."),
		OnboardingPage(title: "Add Widget", description: "Tap 'Add Widget' and look for 'Keepsake' to add it to your Home Screen."),
		OnboardingPage(title: "Add Widget", description: "Tap on your new Keepsake widget, then assign the widget to album of your choice!")
	]
	
	var body: some View {
		TabView(selection: $currentPage) {
			ForEach(0..<pages.count, id: \.self) { index in
				VStack {
					Spacer()
					
					VStack {
						Text(pages[index].title)
							.font(.title)
							.bold()
							.padding(.bottom, 8)
						
						Text(pages[index].description)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 32)
					}
					
					Spacer()
					
					if index == 0 {
						Image("instruction-0")
							.resizable()
							.frame(width: 250, height: 250)
					} else {
						Image("instruction-\(index)")
							.resizable()
							.frame(width: 329, height: 350)
					}
					
					Spacer()
					Spacer()
					Spacer()
				}
				.tag(index)
			}
		}
		.onOpenURL { url in
			loadFolders()
			
			guard url.scheme == "keepsake",
				  url.host == "select-folder",
				  let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
				  let folderQuery = components.queryItems?.first(where: { $0.name == "folder" })?.value
			else {
				print("Invalid deep link: \(url)")
				return
			}
			
			if let album = getAlbum(identifier: folderQuery) {
				navigationManager.path = NavigationPath()
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					navigationManager.path.append(album)
				}
			}
		}
		.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
		.overlay(alignment: .bottom) {
			VStack(spacing: 24) {
				// Navigation button
				Button(action: {
					if currentPage < pages.count - 1 {
						withAnimation {
							currentPage += 1
						}
					} else {
						// Complete onboarding
						onComplete()
					}
				}) {
					Text(currentPage == pages.count - 1 ? "Got it" : "Next")
						.padding(.horizontal, 84)
						.padding(.vertical, 14)
						.background(.white)
						.foregroundColor(.black)
						.bold()
						.cornerRadius(999)
				}
				.padding(.horizontal, 32)
				
				// Page dots
				HStack(spacing: 8) {
					ForEach(0..<pages.count) { index in
						Circle()
							.fill(Color(UIColor(red: 151/255, green: 151/255, blue: 151/255, alpha: 1))
								.opacity(currentPage == index ? 1 : 0.3))
							.frame(width: 10, height: 10)
					}
				}
			}
			.padding(.bottom, 32)
		}
		.preferredColorScheme(.dark)
	}
	
	private func loadFolders() {
		selectedFolderIdentifier = Self.sharedDefaults?.string(forKey: "selectedFolder")
	}
	
	private func getAlbum(identifier: String?) -> PHAssetCollection? {
		guard let identifier = identifier else { return nil }
		return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil).firstObject
	}
}

struct OnboardingPage {
	let title: String
	let description: String
}
