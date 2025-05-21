//
//  NavigationManager.swift
//  keepsake
//
//  Created by Ryan Hangralim on 21/05/25.
//

import SwiftUI

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    
    static let shared = NavigationManager()
}
