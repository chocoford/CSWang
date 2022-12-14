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
                .opacity(loading ? 0 : 1)
            if loading {
                LoadingView(size: 20, strokeColor: .white)
            }
        }
        .onHover { over in
            self.hovering = over
        }
    }
}
