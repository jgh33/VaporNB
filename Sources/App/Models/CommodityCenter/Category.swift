
import Foundation
import Vapor
import FluentPostgreSQL




final public class Category: PostgreSQLModel {
    public var id: Int?
    var name: String
    var desc: String
    var fatherID: Category.ID?
    var isLeaf: Bool
    
    init(name: String, desc: String, fatherID: Category.ID?, isLeaf: Bool) {
        self.name = name
        self.desc = desc
        self.fatherID = fatherID
        self.isLeaf = isLeaf
    }
    
}
