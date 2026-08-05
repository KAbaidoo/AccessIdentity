//
//  JWTManager.swift
//  SharedSecurityKit
//
//  Created by kobby on 05/08/2026.
//

import Foundation
import SwiftJWT

// MARK: - JWT Claims
/// Defines the custom claims payload embedded inside the JSON Web Token.
public struct EmployeeAuthClaims: Claims {
    public let sub: String // Subject (Employee ID)
    public let name: String
    public let exp: Date   // Expiration time
    
    public init(sub: String, name: String, exp: Date = Date(timeIntervalSinceNow: 3600)) {
        self.sub = sub
        self.name = name
        self.exp = exp // Token expires in 1 hour by default
    }
}

// MARK: - JWT Manager
/// Handles generating and verifying JSON Web Tokens for local authentication mocking.
public struct JWTManager {
    
    // In a real application, this secret lives securely on the backend server.
    // For our local mock, we store a static symmetric key.
    private let mockSecretKey = "enterprise_secure_mock_key_2026".data(using: .utf8)!
    
    public init() {}
    
    /// Generates a signed JSON Web Token (JWT) for a given employee profile.
    /// - Parameter profile: The DigitalIDProfile to issue a token for.
    /// - Returns: A base64-url encoded JWT string.
    public func generateToken(for profile: DigitalIDProfile) throws -> String {
        let claims = EmployeeAuthClaims(sub: profile.employeeID.uuidString, name: profile.fullName)
        
        // Initialize the JWT with the custom claims
        var jwt = JWT(claims: claims)
        
        // Sign the token using HMAC-SHA256 and the mock secret key
        let signer = JWTSigner.hs256(key: mockSecretKey)
        let signedToken = try jwt.sign(using: signer)
        
        return signedToken
    }
    
    /// Decodes and verifies the signature and expiration of a JWT.
    /// - Parameter token: The base64-url encoded JWT string.
    /// - Returns: The decoded EmployeeAuthClaims if verification is successful.
    public func verifyToken(_ token: String) throws -> EmployeeAuthClaims {
        // Initialize the verifier with the same symmetric key
        let verifier = JWTVerifier.hs256(key: mockSecretKey)
        
        // Decode and verify the signature
        let jwt = try JWT<EmployeeAuthClaims>(jwtString: token, verifier: verifier)
        
        // Validate standard claims (like checking if 'exp' has passed)
        try jwt.validateClaims()
        
        return jwt.claims
    }
}
