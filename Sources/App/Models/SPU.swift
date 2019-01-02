//
//  SPU.swift
//  App
//
//  Created by 焦国辉 on 2018/8/17.
//

import Foundation
import  Vapor
import FluentPostgreSQL

final class SPU: PostgreSQLUUIDModel {
    var id: UUID?
    
    var name: String
    var desc: String
    var typeID: Type.ID
    var brandID: Brand.ID
    
    init(name: String, desc: String, typeID: Type.ID, brandID: Brand.ID) {
        self.name = name
        self.desc = desc
        self.typeID = typeID
        self.brandID = brandID
    }
}
