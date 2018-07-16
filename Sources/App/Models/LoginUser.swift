
import Vapor
import FluentPostgreSQL


final class LoginUser: PostgreSQLModel {
    var id: Int?
    
    var username: String
    var phone: String
    var password: String

   
 
    init(username: String, phone: String, password: String) {
        self.username = username
        self.phone = phone
        self.password = password
    }
}

extension LoginUser: Content {}
extension LoginUser: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)
        }
    }
}
extension LoginUser: Parameter {}


extension LoginUser {
    var token: Children<LoginUser, Token> {
        return children(\.userID)
    }
}

