//
//  LogoutButton.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/5.
//

import SwiftUI

struct LogoutButton: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Button {
            AuthMiddleware.shared.removeToken()
            Task {
                await store.send(.clear)
            }
        } label: {
            Image(systemName: "rectangle.portrait.and.arrow.right")
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

struct LogoutButton_Previews: PreviewProvider {
    static var previews: some View {
        LogoutButton()
    }
}
