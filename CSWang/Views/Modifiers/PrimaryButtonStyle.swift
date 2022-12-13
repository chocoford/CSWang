//
//  PrimaryButton.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var block: Bool = false
    var loading: Bool = false
    var disabled: Bool = false
    
    private struct PrimaryButtonStyleView<V: View>: View {
        @State private var hovering = false
        var isPressed: Bool
        
        let baseColor = Color.blue
        var block = false
        var disabled = false

        let content: () -> V
        
        var bgColor: Color {
            if disabled {
                return Color.primary.disabled
            } else if isPressed {
                return Color.primary.pressed
            } else if hovering {
                return Color.primary.hovered
            } else {
                return Color.primary.default
            }
        }
        
        var body: some View {
            HStack {
                if block {
                    Spacer()
                }
                content()
                    .padding(.horizontal)
                if block {
                    Spacer()
                }
            }
            .padding(10)
            
            .foregroundColor(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor)
                    .if(!disabled, transform: { content in
                        content
                            .shadow(color: hovering ? .gray : .clear, radius: 1, x: 0, y: 1)
                    })
            )
            .animation(.easeOut(duration: 0.2), value: hovering)
            .onHover { over in
                self.hovering = over
            }
        }
    }
    
    
    func makeBody(configuration: Self.Configuration) -> some View {
        LoadableButtonStyleView(loading: loading) {
            PrimaryButtonStyleView(isPressed: configuration.isPressed, block: block, disabled: disabled) {
                configuration.label
            }
        }
    }
}
