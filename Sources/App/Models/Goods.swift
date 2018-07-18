
import Vapor
import FluentPostgreSQL


final class Goods: PostgreSQLModel {
    var id: Int?
    
    var unitPrice: String
    var name: String
    var drsc: String
    
    
    
//    init(username: String, phone: String, password: String) {
//        self.username = username
//        self.phone = phone
//        self.password = password
//    }
}

//extension ShoppingTrolley: Content {}
//extension ShoppingTrolley: Migration {
//    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.unique(on: \.username)
//        }
//    }
//}
//extension ShoppingTrolley: Parameter {}

