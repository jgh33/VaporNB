//
//  PropertyOption.swift
//  App
//
//  Created by jgh on 2018/9/1.
//

import Foundation
import Vapor
import FluentPostgreSQL




final public class PropertyOption: PostgreSQLModel {
    public var id: Int?
    var propertyID: Property.ID
    var option: String
    
    
    init(propertyID: Property.ID, option: String) {
        self.propertyID = propertyID
        self.option = option
    }
    
}
