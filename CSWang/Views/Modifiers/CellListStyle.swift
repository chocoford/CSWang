//
//  CellListStyle.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

private struct CellListStyleView<V: View>: View {
    @State private var hovering = false
    var isPressed: Bool
    
    let baseColor = Color.blue

    let content: () -> V
    
    var body: some View {
        content()
            .padding()
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

//struct CellListStyle: ListStyle {
//    static func _makeView<SelectionValue>(value: _GraphValue<_ListValue<CellListStyle, SelectionValue>>, inputs: _ViewInputs) -> _ViewOutputs where SelectionValue : Hashable {
//        <#code#>
//    }
//    
//    static func _makeViewList<SelectionValue>(value: _GraphValue<_ListValue<CellListStyle, SelectionValue>>, inputs: _ViewListInputs) -> _ViewListOutputs where SelectionValue : Hashable {
//        <#code#>
//    }
//}
