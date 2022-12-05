//
//  CreateChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

struct CreateChannelView: View {
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack{
                    Text("Initialize")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Create a channel to start")
                }
                .padding()

                NavigationLink("Create the channel") {
                   InviteMembersView()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            
        }
    }
}

struct CreateChannelView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChannelView()
    }
}
