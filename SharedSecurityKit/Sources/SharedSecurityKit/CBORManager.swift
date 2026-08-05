//
//  CBORManager.swift
//  SharedSecurityKit
//
//  Created by kobby on 05/08/2026.
//


import Foundation
import SwiftCBOR

/// Handles the binary serialization of digital credentials into CBOR payloads.
public struct CBORManager {
    
    public init() {}
    
    /// Converts the user's digital ID profile into a CBOR payload.
    /// - Parameter profile: The DigitalIDProfile to encode.
    /// - Returns: An array of bytes (UInt8) representing the compressed CBOR payload.
    public func encodeProfile(_ profile: DigitalIDProfile) throws -> [UInt8] {
        let encoder = CodableCBOREncoder()
        // Encodes the Codable profile directly into a binary CBOR format
        let cborData = try encoder.encode(profile)
        return [UInt8](cborData)
    }
    
    /// Decodes a CBOR payload back into a DigitalIDProfile.
    /// - Parameter payload: The raw CBOR byte array.
    /// - Returns: The reconstructed DigitalIDProfile.
    public func decodeProfile(from payload: [UInt8]) throws -> DigitalIDProfile {
        let decoder = CodableCBORDecoder()
        // Decodes the compressed payload format to extract the raw JSON/Object data
        let profile = try decoder.decode(DigitalIDProfile.self, from: ArraySlice(payload))
        return profile
    }
}
