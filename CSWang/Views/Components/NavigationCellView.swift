//
//  NavigationCellView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct NavigationCellView<V: View, D: View, P : Hashable&Identifiable, SelectionValue>: View where SelectionValue == P.ID {
    @Binding var selection: SelectionValue?
    
    var content: () -> V
    var value: P
    
    var destinationView: () -> D
    
    init(value: P, selection: Binding<SelectionValue?>,
         @ViewBuilder content: @escaping () -> V,
         @ViewBuilder destination: @escaping () -> D) {
        self.content = content
        self.value = value
        self.destinationView = destination
        self._selection = selection
    }
    
    var body: some View {
        navigationLink
    }
    
    @ViewBuilder var navigationLink: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            /// Navigation Split View
            content()
        } else {
            NavigationLink {
                destinationView()
                    .onAppear {
                        selection = value.id
                    }
                    .onDisappear {
                        selection = nil
                    }
            } label: {
                content()
            }
        }
    }
}
