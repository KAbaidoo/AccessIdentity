//
//  DigitalIDProfile.swift
//  SharedSecurityKit
//
//  Created by kobby on 05/08/2026.
//

import Foundation


/// Represents the proprietary corporate ID credential.
public struct DigitalIDProfile: Codable, Equatable {
    public let employeeID: UUID
    public let fullName: String
    public let role: String
    public let clearanceLevel: Int
    public let issuedDate: Date
    
    public init(employeeID: UUID = UUID(), fullName: String, role: String, clearanceLevel: Int, issuedDate: Date = Date()) {
        self.employeeID = employeeID
        self.fullName = fullName
        self.role = role
        self.clearanceLevel = clearanceLevel
        self.issuedDate = issuedDate
    }
}
