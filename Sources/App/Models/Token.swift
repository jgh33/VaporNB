
import Foundation
import Vapor
import FluentPostgreSQL
import Crypto

let longTokenTimeInterval: TimeInterval = 60 * 30   //30分钟
let shortTokenTimeInterval: TimeInterval = 60 * 5   //5分钟

final class Token: PostgreSQLModel {
    var id:Int?
    var userID: LoginUser.ID
    var shortTokenString: String
    var longTokenString: String
    var longTokenExpiryTime: TimeInterval
    var shortTokenExpiryTime: TimeInterval
    
    init(userID: LoginUser.ID) throws {
        self.userID = userID
        self.shortTokenString = try CryptoRandom().generateData(count: 32).base64URLEncodedString()
        self.longTokenString = try CryptoRandom().generateData(count: 64).base64URLEncodedString()
        
        self.longTokenExpiryTime = Date().timeIntervalSince1970 + longTokenTimeInterval
        self.shortTokenExpiryTime = Date().timeIntervalSince1970 + shortTokenTimeInterval
    }

    func makeNewAllTokens() throws -> Self {
        self.shortTokenString = try CryptoRandom().generateData(count: 32).base64URLEncodedString()
        self.longTokenString = try CryptoRandom().generateData(count: 64).base64URLEncodedString()
        
        self.longTokenExpiryTime = Date().timeIntervalSince1970 + longTokenTimeInterval
        self.shortTokenExpiryTime = Date().timeIntervalSince1970 + shortTokenTimeInterval
        return self
    }
    
    func makeNewShortToken() throws -> Self {
        self.shortTokenString = try CryptoRandom().generateData(count: 32).base64URLEncodedString()
        self.shortTokenExpiryTime = Date().timeIntervalSince1970 + shortTokenTimeInterval
        return self
    }
    
}


extension Token: Migration {
    static func prepare(on connection: PostgreSQLConnection)
        -> Future<Void> {
            // 3
            return Database.create(self, on: connection) { builder in
                // 4
                try addProperties(to: builder)
                // 5
                builder.reference(from: \.userID, to: \LoginUser.id)
            }
    }
}
extension Token: Content {}
extension Token: Parameter {}
extension Token {
    var loginUser: Parent<Token, LoginUser> {
        return parent(\.userID)
        
    }
}
