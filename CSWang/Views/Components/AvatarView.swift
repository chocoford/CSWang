//
//  AvatarView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import SwiftUI
import ShapeBuilder

struct AvatarView<S: StringProtocol>: View {
    var url: URL?
    var fallbackText: S
    
    enum AvatarShape {
        case circle
        case rounded
        case tile
    }
    var shape: AvatarShape = .circle
    var size: CGFloat = 28
    
    
    var phText: String {
        String(fallbackText).uppercased()
    }
    
    @ShapeBuilder
    var clipShape: some Shape {
        switch shape {
            case .circle:
                Circle()

            case .rounded:
                RoundedRectangle(cornerRadius: 4)

            case .tile:
                Rectangle()
        }
    }
    
    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            Rectangle()
                .foregroundColor(.gray)
                .overlay(alignment: .center) {
                    Text(phText)
                        .foregroundColor(.white)
                }
        }
        .frame(width: size, height: size, alignment: .center)
        .clipShape(clipShape)
    }
}

struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarView(fallbackText: "ABC")
    }
}
