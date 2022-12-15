//
//  AppState.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation
import Combine

struct AppState {
    var user: UserState = .init()
    var workspace: WorkspaceState = .init()
}

enum AppAction {
    case user(action: UserAction)
    case workspace(action: WorkspaceAction)
//    case channel(action: ChannelAction)
//    /// 铲屎
//    case chanshi(action: CSAction)
    
    /// app action
    case clear
}

typealias AppStore = Store<AppState, AppAction, AppEnvironment>

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = Reducer { state, action, environment in
    switch action {
        case .user(let action):
            return userReducer(state: &state.user, action: action, environment: environment)
                .eraseToAnyPublisher()
            
        case .workspace(let action):
            return workspaceReducer(&state.workspace, action, environment)
            .map{ .workspace(action: $0) }
            .eraseToAnyPublisher()

        case .clear:
            state = .init()
    }
    
    return Empty()
        .eraseToAnyPublisher()
}

func formDic<T>(payload: AnyStreamable<T>, id: KeyPath<T, String>) -> [String: T] {
    var dic: [String : T] = [:]
    for item in payload.items {
        dic[item[keyPath: id]] = item
    }
    return dic
}

#if DEBUG
func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error.localizedDescription)")
    }
}



extension AppState {
    static let preview: AppState = {
        var previewState: AppState = .init(user: .init(tokenInfo: .init(sub: "515970908439969793",
                                                                        iat: 1668064020,
                                                                        exp: 1699620972,
                                                                        scope: "browser",
                                                                        token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1MTU5NzA5MDg0Mzk5Njk3OTMiLCJpYXQiOjE2NjgwNjQwMjAsImV4cCI6MTY5OTYyMDk3Miwic2NvcGUiOiJicm93c2VyIn0.I9VuwQnOwLG0NnlQTyhNalLYX_WaxHmI2DSsdnkR3Vk")),
                                           workspace: .init())
        
        
        // MARK: - workspaces
        previewState.user.userInfo = .loaded(data: .init(user: .init(id: "123", name: "Chocoford", email: nil, avatarURL: URL(string: "https://testres.trickle.so/upload/users/29967960227446785/1666774231375_006mowZngy1fz3u72cx1lj307e06tq2y.jpg")))) 
        previewState.workspace.workspaces = .loaded(data: formDic(payload: load("workspaces.json"), id: \.workspaceID))
        previewState.workspace.currentWorkspaceID = previewState.workspace.allWorkspaces.first?.workspaceID
        previewState.workspace.members = formDic(payload: load("members.json"), id: \.memberID)
        
        // MARK: - channels
        previewState.workspace.channels = .loaded(data: formDic(payload: load("publicGroups.json"), id: \.groupID))
        previewState.workspace.currentChannelID = previewState.workspace.channels.value?.first?.value.groupID
        previewState.workspace.trickles = .loaded(data: [:])
        previewState.workspace.participants = .loaded(data: formDic(payload: load("members.json"), id: \.memberID))
        return previewState
    }()
}


extension AppStore {
    static let preview = AppStore(state: .preview,
                                  reducer: appReducer,
                                  environment: .init())
}

#endif
