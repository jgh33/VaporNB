//
//  Property.swift
//  App
//
//  Created by jgh on 2018/9/1.
//

import Foundation
import Vapor
import FluentPostgreSQL




final public class Property: PostgreSQLModel {
    public var id: Int?
    var name: String
    var categoryID: Category.ID

    
    init(name: String, categoryID: Category.ID) {
        self.name = name
        self.categoryID = categoryID

    }
    
}
