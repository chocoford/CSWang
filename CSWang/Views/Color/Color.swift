//
//  ButtonColor.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI

struct AppColor {
    let `default`: Color
    let hovered: Color
    let pressed: Color
    let active: Color
}


extension Color {
    static let primary = AppColor(default: .init(hue: 309, saturation: 0.6, brightness: 0.95),
                                  hovered: .init(hue: 201, saturation: 0.6, brightness: 1),
                                  pressed: .init(hue: 201, saturation: 0.6, brightness: 0.8),
                                  active: .accentColor)
    
    static let second = AppColor(default: .clear,
                                 hovered: .gray.opacity(0.5),
                                 pressed: .gray.opacity(0.6),
                                 active: .accentColor)
}

