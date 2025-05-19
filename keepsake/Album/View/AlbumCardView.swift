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

    init(title: String) {
        self.title = title
        self.gradient = AlbumCardView.randomGradient()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient)
                .frame(width: 165, height: 165)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
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


#Preview {
    AlbumCardView(title: "Brat")
}
