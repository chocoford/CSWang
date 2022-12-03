//
//  LoginView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI
import Combine

struct LoginSheet: ViewModifier {
    @EnvironmentObject var store: AppStore
    @State private var show: Bool = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $show) {
                LoginView()
            }
            .task {
                await checkAuth()
            }
            .onReceive(store.state.user.hasLogin) { hasLogin in
                if !hasLogin {
                    show = true
                }
            }
    }
    
    private func checkAuth() async {
        guard let userInfo = AuthMiddleware.shared.getTokenFromKeychain() else {
            show = true
            return
        }
        await store.send(.user(action: .setUserInfo(userInfo: userInfo)))
    }
}

extension View {
    func loginSheet() -> some View {
        modifier(LoginSheet())
    }
}

struct LoginView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var signInModel = SignInViewModel()
    @State var cancellables: [AnyCancellable] = []
    
    
    var body: some View {
        VStack {
            Image("TrickleLogo")
            Button {
                getAuth()
            } label: {
                Text("Login to Trickle")
            }
            .buttonStyle(PrimaryButtonStyle())
        }.padding()
    }
    
    func getAuth() {
        signInModel.signIn(to: "https://devapp.trickle.so/app/authorization?third_party=CSWang", scheme: "CSWang")
            .sink { completion in

            } receiveValue: { token in
                print(token)
                Task {
                    await store.send(.user(action: .getUserInfo(token: token)))
                }
            }
            .store(in: &cancellables)
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif
