//
//  SKU.swift
//  App
//
//  Created by 焦国辉 on 2018/8/17.
//

import Foundation
import  Vapor
import FluentPostgreSQL

final class SKU: PostgreSQLUUIDModel {
    var id: UUID?
    
    var name: String
    var images: [String]
    var price: Double
    var spuID: SPU.ID
    
    init(name: String, images: [String], price: Double, spuID: SPU.ID) {
        self.name = name
        self.images = images
        self.price = price
        self.spuID = spuID
    }
}
