
import Foundation
import Vapor
import FluentPostgreSQL




final public class Brand: PostgreSQLModel {
    public var id:Int?
    var logo: String?
    var name: String
    var chineseName: String?
    var chandi: String
    var desc: String
    var status: String = "ok"
    
    init(logo: String, name: String, chineseName: String, chandi: String, desc: String) throws {
        self.logo = logo
        self.name = name
        self.chineseName = chineseName
        self.chandi = chandi
        self.desc = desc
    }
}
