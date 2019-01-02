//
//  Type.swift
//  App
//
//  Created by 焦国辉 on 2018/8/17.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Type: PostgreSQLUUIDModel {
    var id: UUID?
    
    var name: String
    var desc: String
    var superID: UUID?
    
    
    init(name: String, desc: String, superID: UUID? = nil) {
        self.name = name
        self.desc = desc
        self.superID = superID
    }
}
