//
//  MembersView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/12/1.
//

import SwiftUI

struct Flex: Layout {
    enum FlexDirection {
        case row
        case column
    }
    var direction: FlexDirection = .row
    
    var gap: CGFloat = 0
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        switch direction {
            case .row:
                return CGSize(width: proposal.width ?? .infinity, height: proposal.height ?? .zero)
//                return CGSize;
                
            case .column:
                return CGSize(width: proposal.width ?? .zero, height: proposal.height ?? .infinity)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var nextX = bounds.minX
        var nextY = bounds.minY

        for subView in subviews {
            subView.place(
                at: CGPoint(x: nextX, y: nextY),
                anchor: .topLeading,
                proposal: .zero)
            nextX += subView.sizeThatFits(proposal).width + gap
        }
    }
    
    
}

struct MembersView: View {
    @EnvironmentObject var store: AppStore
    
    let columns = [GridItem(.fixed(400)), GridItem(.fixed(400))]
    var body: some View {
        ScrollView {
//        Flex {
            ForEach(store.state.workspace.allMembers ?? [],
                    id: \.memberID) { member in
                MemberCardView(userInfo: .init(name: member.name, avatarURL: URL(string: member.avatarURL)))
            }
//        }
        }
    }
}

struct MembersView_Previews: PreviewProvider {
    static var previews: some View {
        MembersView()
            .environmentObject(AppStore(state: .preview, reducer: appReducer, environment: .init()))
    }
}
