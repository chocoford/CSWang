//
//  CellList.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/15.
//

import SwiftUI


struct CellList<V: View, SelectionValue: Hashable, Data: RandomAccessCollection>: View where Data.Element: Identifiable, SelectionValue == Data.Element.ID {
    
    var content: (_ item: Data.Element) -> V
    var items: Data
    
    @Binding var selected: SelectionValue?
    
    init(_ items: Data, selection: Binding<SelectionValue?>, content: @escaping (_ item: Data.Element) -> V) where Data.Element: Identifiable {
        self.content = content
        self._selected = selection
        self.items = items
    }
    
    var body: some View {
        /// `NavigationSpliView` in iOS must use with `List`
        if UIDevice.current.userInterfaceIdiom != .phone {
            scollView
        } else {
            listView
        }
    }
    
    @ViewBuilder var scollView: some View {
        ScrollView {
            ForEach(items) { item in
                content(item)
                    .onTapGesture {
                        selected = item.id
                    }
                    .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder var listView: some View {
        List(items, selection: $selected) { item in
            content(item)
        }
        .listStyle(.sidebar)
    }
}
