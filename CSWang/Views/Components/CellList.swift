//
//  CellList.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/15.
//

import SwiftUI

struct CellList<V: View, T: Identifiable&Hashable>: View {
    
    var content: (_ item: T) -> V
    var items: [T]
    
    @Binding var selected: T?
    
    init(_ items: [T], selected: Binding<T?>, content: @escaping (_ item: T) -> V) {
        self.content = content
        self._selected = selected
        self.items = items
    }
    
    var body: some View {
#if os(macOS)
        scollView
#elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            scollView
        } else {
            listView
        }
#endif
    }
    
    @ViewBuilder var scollView: some View {
        ScrollView {
            ForEach(items) { item in
                content(item)
                    .onTapGesture {
                        selected = item
                    }
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder var listView: some View {
        List(items, selection: $selected) { item in
            content(item)
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
    }
   
}
