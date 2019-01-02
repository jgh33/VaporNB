//
//  PropertyOption.swift
//  App
//
//  Created by 焦国辉 on 2018/8/17.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class PropertyOption: PostgreSQLUUIDModel {
    var id: UUID?
    
    var option: String
    var propertyID: Property.ID
    
    init(option: String, propertyID: Property.ID) {
        self.option = option
        self.propertyID = propertyID
    }
}
