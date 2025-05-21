//
//  NavigationManager.swift
//  keepsake
//
//  Created by Agustio Maitimu on 20/05/25.
//

import SwiftUI

class NavigationManager: ObservableObject {
	@Published var path = NavigationPath()
	
	static let shared = NavigationManager()
}
