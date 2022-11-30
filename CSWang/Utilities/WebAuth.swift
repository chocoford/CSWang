//
//  WebAuth.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/28.
//

import Foundation
import AuthenticationServices
import Combine

enum SignInError: Error {
    case invalidURL
    case invalidResponse
    case missSelf
}

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var running: Bool = false
    
    var cancellables: [AnyCancellable] = []
    
    #if os(macOS)
    typealias ASPresentationAnchor = NSWindow
    #elseif os(iOS)
    typealias ASPresentationAnchor = UIWindow
    #endif
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
    
    
    private func processCallbackUrl(_ callbackURL: URL) throws -> String {
        // The callback URL format depends on the provider. For this example:
        //   exampleauth://auth?token=1234
        let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems
        let token = queryItems?.filter({ $0.name == "token" }).first?.value
        guard let token = token else {
            DispatchQueue.main.async {
                self.running = false
            }
            throw SignInError.invalidResponse
        }
        
        return token
    }
    
    ///
    /// - Parameters:
    ///   - urlString: <#urlString description#>
    ///   - scheme: <#scheme description#>
    /// - Returns: `Token`
    func signIn(to urlString: String, scheme: String) -> AnyPublisher<String, Error> {
        running = true
        guard let authURL = URL(string: urlString) else {
            return Fail(error: SignInError.invalidURL).eraseToAnyPublisher()
        }

        let signinPromise = Future<URL, Error> { completion in
            let session = ASWebAuthenticationSession(url: authURL,
                                                     callbackURLScheme: scheme) { callbackURL, error in
                if let err = error {
                    completion(.failure(err))
                } else if let url = callbackURL {
                    completion(.success(url))
                }

            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
        

        return signinPromise
            .tryMap({ [weak self] in
                guard let this = self else {throw SignInError.missSelf}
                return try this.processCallbackUrl($0)
            })
            .eraseToAnyPublisher()
    }
}
