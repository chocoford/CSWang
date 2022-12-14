//
//  GameView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/12.
//

import SwiftUI
import Combine

struct GameView: View {
    @EnvironmentObject var store: AppStore
    
    var workspaceState: WorkspaceState {
        store.state.workspace
    }
    
    var workspace: WorkspaceData? {
        workspaceState.currentWorkspace
    }
    
    var channel: Loadable<GroupData> {
        workspaceState.currentChannel
    }
    
    var memberInfo: MemberData? {
        workspace?.userMemberInfo
    }

    @Binding var show: Bool
    
    @State private var points: [Int?] = .init(repeating: nil, count: 6)
    @State private var rolling = false
    @State private var timer: AnyCancellable?
    
    var didPlay: Bool {
        points.allSatisfy({
            $0 != nil
        })
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Text("Gamble")
                    .font(.title)
                    .padding()
                
                Text("现阶段该游戏并为开发好，但总的来说就是一个扔骰子的游戏。游戏规则：将摇出4个数字，分别在以下位置一次进行填空，结果为计算结果")
                    .font(.footnote)
                
                // 游戏规则：[x1x2](x3*x4) % [x3x2](x1*x4)
                HStack {
                    PointContainer(text: points[0]?.formatted())
                    PointContainer(text: points[1]?.formatted())
                    PointContainer(text: points[2]?.formatted())
                    PointContainer(text: points[3]?.formatted())
                }
                .padding()
                
                Text("Rule: `[x1x2](x3*x4) % [x3x2](x1*x4)`")
                
                if didPlay {
                    let points = points.compactMap{ $0 }
                    Text("\(points[0])\(points[1])(\(points[2])*\(points[3])) % \(points[2])\(points[1])(\(points[0])*\(points[3])) = \(getResult())")
                        .padding()
                }
                
                //            if rolling {
                //                Button {
                //                    makeScore()
                //                } label: {
                //                    Text("Stop")
                //                }
                //                .buttonStyle(PrimaryButtonStyle())
                //            } else {
                if !didPlay {
                    Button {
                        rollScore()
                    } label: {
                        Text("Roll")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            if didPlay {
                LoadingView(size: 15)
                    .frame(width: 20, height: 20)
                    .padding(16)
            }
            
        }
    }
    
    private func PointContainer(text: String?) -> some View {
        Text(text ?? "?")
            .font(.title2)
            .padding()
            .background(.thinMaterial)
            .containerShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func gamble() async {
        guard let member = memberInfo else { return }
        
        if case .ready = workspaceState.userGambleState {
            let score = getResult()
            await store.send(.workspace(action: .publishScore(score: score)))
            await store.send(.workspace(action: .getUserCSInfo(memberData: member)))
            await store.send(.workspace(action: .summarizeIfNeeded))
            await store.send(.workspace(action: .weekStateCheck))
        }

    }
    
    func rollScore() {
//        rolling = true
//        timer = Timer.publish(every: 0.05, on: .main, in: .common)
//            .autoconnect()
//            .sink { _ in
//                let score = [Int].init(repeating: 0, count: 6).map { _ in
//                    Int.random(in: 1...6)
//                }
//                points = score
//            }
        points = [Int].init(repeating: 0, count: 6).map { _ in
            Int.random(in: 1...6)
        }
        
        Task {
            await gamble()
            self.show = false
        }
    }
    
    func makeScore() {
        rolling = false
        timer?.cancel()
    }
    
    func getResult() -> Int {
        let points = points.compactMap{ $0 }
        let left = Int("\(points[0])\(points[1])\(points[2]*points[3])") ?? 0
        let right = Int("\(points[2])\(points[1])\(points[0]*points[3])") ?? 0
        
        return left % right
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(show: .constant(true))
    }
}
