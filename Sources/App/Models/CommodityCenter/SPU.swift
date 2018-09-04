//
//  SPU.swift
//  App
//
//  Created by jgh on 2018/9/1.
//

import Foundation
import Vapor
import FluentPostgreSQL




final public class SPU: PostgreSQLModel {
    public var id: Int?
    var name: String
    var desc: String
    var fatherID: SPU.ID?
    var isLeaf: Bool
    
    init(name: String, desc: String, fatherID: SPU.ID?, isLeaf: Bool) {
        self.name = name
        self.desc = desc
        self.fatherID = fatherID
        self.isLeaf = isLeaf
    }
    
}
