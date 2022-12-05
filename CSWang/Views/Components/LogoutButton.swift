//
//  LogoutButton.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/5.
//

import SwiftUI

struct LogoutButton: View {
    var body: some View {
        Button {
            AuthMiddleware.shared.removeToken()
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
        }
    }
}

struct LogoutButton_Previews: PreviewProvider {
    static var previews: some View {
        LogoutButton()
    }
}
