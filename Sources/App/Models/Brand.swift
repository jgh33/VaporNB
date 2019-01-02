//
//  Brand.swift
//  App
//
//  Created by 焦国辉 on 2018/8/17.
//

import Foundation
import  Vapor
import FluentPostgreSQL

final class Brand: PostgreSQLUUIDModel {
    var id: UUID?
    
    var name: String
    var desc: String
    var logo: String
    var website: String?
    var encodeType: String
    
    init(name: String, desc: String, logo: String, website: String? = nil, encodeType: String) {
        self.name = name
        self.desc = desc
        self.logo = logo
        self.website = website
        self.encodeType = encodeType
    }
}
