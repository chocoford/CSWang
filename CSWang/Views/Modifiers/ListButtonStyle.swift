//
//  ListButtonStyle.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import SwiftUI

struct ListButtonStyle: ButtonStyle {
    private struct ListButtonStyleView<V: View>: View {
        @State private var hovering = false
        var isPressed: Bool
        
        let baseColor = Color.blue

        let content: () -> V
        
        var body: some View {
            content()
//                .contentShape(RoundedRectangle(cornerRadius: 8))
//                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isPressed ? Color.gray.opacity(0.6) : hovering ? Color.gray.opacity(0.5) : Color.clear)
                )
                .animation(.easeOut(duration: 0.2), value: hovering)
                .onHover { over in
                    self.hovering = over
                }
        }
    }
    
    
    func makeBody(configuration: Self.Configuration) -> some View {
        ListButtonStyleView(isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

struct ListLabelStyle: LabelStyle {
    var active: Bool
    private struct ListButtonStyleView<V: View>: View {
        
        @State private var hovering = false
        var active: Bool
        
        let content: () -> V
        
        var body: some View {
            content()
                .padding()
                .if(UIDevice.current.userInterfaceIdiom != .phone, transform: { view in
                    view.background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(active ? Color.second.active :
                                    hovering ? Color.second.hovered : Color.second.default)
                    )
                })
                .animation(.easeOut(duration: 0.2), value: hovering)
                .onHover { over in
                    self.hovering = over
                }
        }
    }
    
    
    func makeBody(configuration: Self.Configuration) -> some View {
        ListButtonStyleView(active: active) {
            configuration.title
        }
    }
}
