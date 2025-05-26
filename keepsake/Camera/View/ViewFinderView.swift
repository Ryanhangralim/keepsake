//
//  ViewFinderView.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import SwiftUI

struct ViewfinderView: View {
	@Binding var image: Image?
	
	var body: some View {
		if let image = image {
			image
				.resizable()
				.clipShape(RoundedRectangle(cornerRadius: 20))
				.scaledToFit()
				.background(.black)
				.padding(.horizontal, 30)
				.padding(.top, 32)
		}
	}
}
struct ViewfinderView_Previews: PreviewProvider {
    static var previews: some View {
        ViewfinderView(image: .constant(Image(systemName: "pencil")))
    }
}
