//
//  LoginView.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import SwiftUI
import Combine

struct LoginSheet: ViewModifier {
    @Binding var show: Bool
    
    init(show: Binding<Bool>) {
        self._show = show
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $show) {
                LoginView()
            }
            .onAppear {
                show = true
            }
    }
}

extension View {
    func loginSheet(show: Binding<Bool>) -> some View {
        modifier(LoginSheet(show: show))
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
//        signInModel.signIn(to: "http://devapp.trickle.so/app/authorization?third_party=CSWang", scheme: "CSWang")
//            .sink { completion in
//
//            } receiveValue: { token in
//                print(token)
//                Task {
//                    await store.send(.getUserInfo(token: token))
//                }
//            }
//            .store(in: &cancellables)


        Task {
            let token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1MTU5NzA5MDg0Mzk5Njk3OTMiLCJpYXQiOjE2NjgwNjQwMjAsImV4cCI6MTY5OTYyMDk3Miwic2NvcGUiOiJicm93c2VyIn0.I9VuwQnOwLG0NnlQTyhNalLYX_WaxHmI2DSsdnkR3Vk"
            await store.send(.user(action: .getUserInfo(token: token)))
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
#endif
