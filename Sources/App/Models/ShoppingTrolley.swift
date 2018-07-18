
import Vapor
import FluentPostgreSQL

typealias RMB = Int   //单位为分

final class ShoppingTrolley: PostgreSQLModel {
    var id: Int?
    
    var userID: String
    var goodsList: [Goods]
    var totalPrice: RMB
    
    
    
//    init(username: String, phone: String, password: String) {
//        self.username = username
//        self.phone = phone
//        self.password = password
//    }
}

extension ShoppingTrolley: Content {}
extension ShoppingTrolley: Migration {
//    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.unique(on: \.username)
//        }
//    }
}
extension ShoppingTrolley: Parameter {}



