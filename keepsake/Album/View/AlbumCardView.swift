//
//  AlbumCardView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 19/05/25.
//

import SwiftUI

struct AlbumCardView: View {
    let title: String
    let gradient: LinearGradient
    let metadata: AlbumMetadata

    init(title: String, metadata: AlbumMetadata) {
        self.title = title
        self.gradient = AlbumCardView.randomGradient()
        self.metadata = metadata
    }

    var body: some View {
        VStack {
            ZStack {
                Color(hex: metadata.colorHex)
                    .aspectRatio(1.0, contentMode: .fill)

                VStack(spacing: 8) {
                    Text(metadata.emoji)
                        .font(.system(size: 48))

                    Text(title)
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                }
            }
            .frame(width: 165, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }

    static func randomGradient() -> LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing),
            LinearGradient(colors: [.yellow, .red], startPoint: .bottomLeading, endPoint: .topTrailing),
            LinearGradient(colors: [.mint, .teal], startPoint: .top, endPoint: .bottomTrailing),
            LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom),
            LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing),
            LinearGradient(colors: [.cyan, .mint], startPoint: .top, endPoint: .bottomTrailing),
            LinearGradient(colors: [.teal, .green], startPoint: .bottom, endPoint: .top),
            LinearGradient(colors: [.brown, .yellow], startPoint: .bottomLeading, endPoint: .topTrailing),
            LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        ]

        return gradients.randomElement()!
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
    
    // Add a method to convert Color to hex string
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    AlbumCardView(title: "Vacation 2024", metadata: AlbumMetadata(emoji: "🌴", colorHex: "#FF5F6D"))
}
