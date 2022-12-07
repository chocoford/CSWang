//
//  WorkspaceChooseView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/30.
//

import SwiftUI

struct WorkspaceChooseSheet: ViewModifier {
    @EnvironmentObject var store: AppStore
    @State private var show: Bool = false
    
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $show) {
                ScrollView {
                    WorkspaceChooseView()
                }
                .padding(20)
                .frame(width: 300, height: 400, alignment: .center)
//                .background(.ultraThickMaterial,
//                            in: RoundedRectangle(cornerRadius: 12))
            }

            .onAppear {
                if store.state.user.userInfo.value != nil && store.state.workspace.currentWorkspaceID == nil {
                    show = true
                }
            }
            .onChange(of: store.state.user.userInfo.value) { newValue in
                if newValue != nil && store.state.workspace.currentWorkspaceID == nil {
                    show = true
                }
            }
            .onChange(of: store.state.workspace.currentWorkspaceID) { newValue in
                if newValue != nil {
                    show = false
                }
            }
    }
}

extension View {
    func workspaceChooseSheet() -> some View {
        modifier(WorkspaceChooseSheet())
    }
}


struct WorkspaceChooseView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(store.state.workspace.allWorkspaces),
                    id: \.workspaceID) { workspace in
                WorkspaceCellView(workspace: workspace)
            }
        }
        .onAppear {
            Task {
                let userID = store.state.user.userInfo.value?.user.id ?? ""
                await store.send(.workspace(action: .listWorkspaces(userID: userID)))
            }
        }
    }
}

struct WorkspaceCellView: View {
    var workspace: WorkspaceData
    var selected: Bool = false
    
    var body: some View {
        Label {
            HStack {
                AvatarView(url: URL(string: workspace.logo),
                           fallbackText: String(workspace.name.prefix(1)),
                           shape: .rounded)
                Text(workspace.name)
                    .font(.title2)
                    .lineLimit(1)
                Spacer()
            }
        } icon: {

        }
        .labelStyle(ListLabelStyle(active: selected))
    }
}


#if DEBUG
struct WorkspaceChooseView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            WorkspaceChooseView()
                .environmentObject(AppStore.preview)
        }
        .padding(20)
        .frame(width: 300, height: 500, alignment: .center)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
#endif
