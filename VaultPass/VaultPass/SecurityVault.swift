//
//  SecurityVault.swift
//  VaultPass
//
//  Created by kobby on 05/08/2026.
//

import Foundation
import CryptoKit
import Security

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    
    var errorDescription: String? {
        switch self {
        case .duplicateEntry: return "The key already exists in the Keychain."
        case .unknown(let status): return "An unknown Keychain error occurred: \(status)"
        case .itemNotFound: return "The requested key was not found in the Keychain."
        }
    }
}

// MARK: - Keychain Manager
/// Manages the secure storage of cryptographic keys within the iOS Keychain.
struct KeychainManager {
    
    /// A unique tag to identify our encryption key in the Keychain
    private let keyTag = "com.vaultpass.masterKey".data(using: .utf8)!
    
    /// Stores a CryptoKit SymmetricKey securely in the Keychain.
    func storeKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data(Array($0)) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateEntry
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Retrieves the stored SymmetricKey from the Keychain.
    func retrieveKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let keyData = item as? Data else {
            throw KeychainError.itemNotFound
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Deletes the stored key (useful for app resets or security lockouts).
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}

// MARK: - Crypto Manager
/// Handles symmetric encryption and decryption using AES-GCM.
struct CryptoManager {
    
    private let keychain = KeychainManager()
    
    /// Retrieves the existing key or generates a new one if it doesn't exist.
    private func getOrGenerateKey() throws -> SymmetricKey {
        do {
            return try keychain.retrieveKey()
        } catch KeychainError.itemNotFound {
            let newKey = SymmetricKey(size: .bits256)
            try keychain.storeKey(newKey)
            return newKey
        }
    }
    
    /// Encrypts raw data using AES-GCM and returns the combined sealed box data.
    func encrypt(data: Data) throws -> Data {
        let key = try getOrGenerateKey()
        // AES.GCM is the required standard for encrypting the raw data
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // Returns the combined data (nonce + ciphertext + authentication tag)
        guard let combinedData = sealedBox.combined else {
            throw NSError(domain: "CryptoManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to combine sealed box."])
        }
        
        return combinedData
    }
    
    /// Decrypts a previously sealed AES-GCM box back into raw data.
    func decrypt(combinedData: Data) throws -> Data {
        let key = try getOrGenerateKey()
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
}
