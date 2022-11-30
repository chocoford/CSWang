//
//  Utils.swift
//  CSWang
//
//  Created by Dove Zachary on 2022/11/29.
//

import Foundation
import JWTDecode

func decodeToken(token: String) -> TokenInfo? {
    do {
        let jwt = try decode(jwt: token)
        guard let sub = jwt["sub"].string,
              let iat = jwt["iat"].integer,
              let exp = jwt["exp"].integer,
              let scope = jwt["scope"].string else {
            return nil
        }
        return TokenInfo(sub: sub, iat: iat, exp: exp, scope: scope, token: token)
    } catch {
        return nil
    }

}
