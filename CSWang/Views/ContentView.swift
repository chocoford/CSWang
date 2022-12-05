//
//  ContentView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        WorkspacessListView()
        .padding()
        .loginSheet()
        .onChange(of: store.state.workspace.currentWorkspaceID) { newValue in
            if newValue != nil {
                checkChannel()
            }
        }
    }
    
    
    private func checkChannel() {
//        store.state.workspace.currentWorkspace
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppStore(state: .preview,
                                        reducer: appReducer,
                                        environment: .init()))
    }
}
#endif
