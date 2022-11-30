//
//  ContentView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    
    @State var showLoginView = false
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .loginSheet(show: $showLoginView)
        .onChange(of: store.state.user.userInfo) { newValue in
            if newValue != nil {
                showLoginView = false
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
