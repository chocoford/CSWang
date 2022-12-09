//
//  SecondaryButtonStyle.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/10.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    var block: Bool = false
    
    private struct PrimaryButtonStyleView<V: View>: View {
        @State private var hovering = false
        var isPressed: Bool
        
        var block = false

        let content: () -> V
        
        var body: some View {
            HStack {
                if block {
                    Spacer()
                }
                content()
                if block {
                    Spacer()
                }
            }
            .padding(10)
            .foregroundColor(Color.white)
            .background(
                isPressed ? Color.second.pressed : hovering ? Color.second.hovered : Color.second.default
            )
            .containerShape(RoundedRectangle(cornerRadius: 8))
            .animation(.easeOut(duration: 0.2), value: hovering)
            .onHover { over in
                self.hovering = over
            }
        }
    }
    
    
    func makeBody(configuration: Self.Configuration) -> some View {
        PrimaryButtonStyleView(isPressed: configuration.isPressed, block: block) {
            configuration.label
        }
    }
}
