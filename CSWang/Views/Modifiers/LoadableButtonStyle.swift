//
//  LoadableButtonStyle.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/13.
//

import SwiftUI

struct LoadableButtonStyleView<V: View>: View {
    var loading: Bool = false
    @State private var hovering = false
    
    let content: () -> V
    
    var body: some View {
        ZStack {
            content()
                .disabled(!loading)
//            if loading {
//                Text("Loading...")
//                GeometryReader { geometry in
//                LoadingView(size: 4)
//                    .background(.regularMaterial)
//                }
//            }
        }
        
//        .foregroundColor(Color.white)
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(isPressed ? Color.primary.pressed : hovering ? Color.primary.hovered : Color.primary.default)
//                .shadow(color: hovering ? .gray : .clear, radius: 1, x: 0, y: 1)
//        )
//        .animation(.easeOut(duration: 0.2), value: hovering)
        .onHover { over in
            self.hovering = over
        }
    }
}
