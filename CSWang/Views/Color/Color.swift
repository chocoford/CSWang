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
}


extension Color {
    static let primary = AppColor(default: .init(hue: 309, saturation: 0.6, brightness: 0.95),
                                  hovered: .init(hue: 201, saturation: 0.6, brightness: 1),
                                  pressed: .init(hue: 201, saturation: 0.6, brightness: 0.8))
}

