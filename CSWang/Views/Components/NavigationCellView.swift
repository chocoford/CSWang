//
//  NavigationCellView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct NavigationCellView<V: View, D: View, P : Hashable>: View {
    
    var content: () -> V
    var value: P
    
    var destinationView: () -> D
    
    init(value: P, @ViewBuilder content: @escaping () -> V, destination: @escaping () -> D) {
        self.content = content
        self.value = value
        self.destinationView = destination
    }
    
    var body: some View {
        ZStack {
            content()
            navigationLink
                .opacity(0)
                .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder var navigationLink: some View {
        if #available(iOS 16.0, *), #available(macOS 13.0, *) {
            NavigationLink(value: value) {
                EmptyView()
            }
        } else {
            NavigationLink {
                destinationView()
            } label: {
                EmptyView()
            }
        }
    }
}
