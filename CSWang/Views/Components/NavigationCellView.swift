//
//  NavigationCellView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct NavigationCellView<V: View, P : Hashable>: View {
    
    var content: () -> V
    var value: P
    
    init(value: P, @ViewBuilder content: @escaping () -> V) {
        self.content = content
        self.value = value
    }
    
    var body: some View {
        ZStack {
            NavigationLink(value: value) {
                EmptyView()
            }
            .opacity(0)
            .buttonStyle(.plain)
            
            content()
        }
    }
}
