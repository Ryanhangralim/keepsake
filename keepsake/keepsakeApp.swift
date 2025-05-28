//
//  keepsakeApp.swift
//  keepsake
//
//  Created by Ryan Hangralim on 16/05/25.
//

import SwiftUI

@main
struct keepsakeApp: App {
	
	init() {
		// Inline Navigation Title
		UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
	}
	
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "keepsake",
              url.host == "select-folder",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let folderQuery = components.queryItems?.first(where: { $0.name == "folder" })?.value
        else {
            print("Invalid deep link: \(url)")
            return
        }
        
        UserDefaults(suiteName: "group.bratss.keep")?.set(folderQuery, forKey: "selectedFolder")
    }
}

fileprivate extension UINavigationBar {
    
    static func applyCustomAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
