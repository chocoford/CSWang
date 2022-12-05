//
//  ChannelView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/2.
//

import SwiftUI

enum CSInfo: String, CaseIterable {
    case immunityNum
    case lastCleanDate
    case nextCleanDate

    var localized: String {
        switch self {
            case .immunityNum:
                return "豁免权"
            case .lastCleanDate:
                return "上一次铲屎时间"
            case .nextCleanDate:
                return "下一次铲屎时间"
        }
    }
}

extension CSInfo: Identifiable {
    var id: String {
        return self.rawValue
    }
}

struct ChannelView: View {
    @EnvironmentObject var store: AppStore
    
    var workspace: WorkspaceData? {
        store.state.workspace.currentWorkspace
    }
    
    var channel: Loadable<GroupData?> {
        store.state.workspace.channel.currentChannel
    }
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }
    
    var body: some View {
        content
    }
    
    
    @ViewBuilder private var content: some View {
        switch channel {
            case .notRequested:
                notRequestedView
            case .isLoading(let last):
                loadingView(last ?? nil)
            case .loaded(let data):
                if let workspace = workspace,
                   let _ = data {
                    VStack {
                        AvatarView(url: URL(string: memberInfo?.avatarURL ?? ""),
                                   fallbackText: String(memberInfo?.name.prefix(2) ?? ""),
                                   size: 80)
                        
                        Text(memberInfo?.name ?? "Unknown")
                            .font(.title)
                            .fontWeight(.bold)
                        List {
                            ForEach(CSInfo.allCases) { info in
                                HStack {
                                    Text(info.localized)
                                    Spacer()
                                    Text("0")
                                }
                            }
                        }
                        Spacer()
                        
                    }
                    .navigationTitle(workspace.name)
                } else {
                    CreateChannelView()
                }
            case .failed(let error):
                failedView(error)
        }
       
    }
}

// MARK: - Loading Content
private extension ChannelView {
    var notRequestedView: some View {
        Text("No data")
    }
    
    func loadingView(_ previouslyLoaded: GroupData?) -> some View {
        VStack {
            LoadingView()
            Text("Loading...")
        }
    }
    
    func failedView(_ error: Error) -> some View {
        ErrorView(error: error, retryAction: {
        })
    }
}

struct ChannelView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChannelView()
                .environmentObject(AppStore.preview)
        }
    }
}
