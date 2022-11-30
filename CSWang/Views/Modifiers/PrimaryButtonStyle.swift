//
//  PrimaryButton.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    private struct PrimaryButtonStyleView<V: View>: View {
        @State private var hovering = false
        var isPressed: Bool
        
        let baseColor = Color.blue

        let content: () -> V
        
        var body: some View {
            content()
                .padding(10)
                .foregroundColor(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isPressed ? Color.primary.pressed : hovering ? Color.primary.hovered : Color.primary.default)
//                        .if(self.hovering, transform: { view in
//                            view
                        .shadow(color: hovering ? .gray : .clear, radius: 1, x: 0, y: 1)
//                        })
                )
//                .animation(.easeOut(duration: 0.2), value: isPressed)
                .animation(.easeOut(duration: 0.2), value: hovering)
            .onHover { over in
                self.hovering = over
            }
        }
    }
    
    
    func makeBody(configuration: Self.Configuration) -> some View {
        PrimaryButtonStyleView(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}
