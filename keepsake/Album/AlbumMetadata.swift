//
//  AlbumMetadata.swift
//  keepsake
//
//  Created by Ryan Hangralim on 20/05/25.
//

import Foundation

struct AlbumMetadata: Codable {
    let emoji: String
    let colorHex: String
    
    static let defaultMetadata = AlbumMetadata(emoji: "📷", colorHex: "#CCCCCC")
}
