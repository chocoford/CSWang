//
//  MemberCardView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import SwiftUI

struct AppUserInfo {
    let name: String
    let avatarURL: URL?
}

struct MemberCardView: View {
    var userInfo: AppUserInfo
    
    @State private var hovering: Bool = false
    
    var body: some View {
        VStack {
            AvatarView(url: userInfo.avatarURL, fallbackText: String(userInfo.name.prefix(2)), size: 64)
            
            Text(userInfo.name).font(.title3)
        }
        .padding(40)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
        .offset(y: hovering ? -20 : 0)
//        .shadow(radius: 10, y: 20)
        .onHover { hover in
            withAnimation(.spring()) {
                hovering = hover
            }
        }
//        .frame(width: 200, height: 300)
    }
}

struct MemberCardView_Previews: PreviewProvider {
    static var previews: some View {
        MemberCardView(userInfo: .init(name: "Chocoford",
                                       avatarURL: URL(string: "https://testres.trickle.so/upload/users/29967960227446785/1666774231375_006mowZngy1fz3u72cx1lj307e06tq2y.jpg")))
    }
}
