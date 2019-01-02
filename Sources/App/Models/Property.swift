//
//  Property.swift
//  App
//
//  Created by 焦国辉 on 2018/8/17.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Property: PostgreSQLUUIDModel {
    var id: UUID?
    
    var name: String
    var typeID: Type.ID
    
    init(name: String, typeID: Type.ID) {
        self.name = name
        self.typeID = typeID
    }
}
