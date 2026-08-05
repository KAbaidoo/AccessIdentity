//
//  VaultDashboardView.swift
//  VaultPass
//
//  Created by kobby on 05/08/2026.
//


import SwiftUI
import SharedSecurityKit
import CryptoKit

struct VaultDashboardView: View {
    // MARK: - Managers
    private let cborManager = CBORManager()
    private let cryptoManager = CryptoManager()
    
    // MARK: - State
    @State private var originalProfile: DigitalIDProfile?
    @State private var encryptedData: Data?
    @State private var decryptedProfile: DigitalIDProfile?
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // MARK: - Header
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.green)
                    
                    Text("Secure ID Vault")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top)
                
                Divider()
                
                // MARK: - Action Buttons
                HStack(spacing: 15) {
                    Button(action: {
                        generateAndEncryptProfile()
                    }) {
                        Label("Encrypt ID", systemImage: "lock.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        decryptAndDecodeProfile()
                    }) {
                        Label("Decrypt ID", systemImage: "lock.open.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(encryptedData == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(encryptedData == nil)
                }
                .padding(.horizontal)
                
                // MARK: - Data Visualization
                VStack(spacing: 20) {
                    // 1. Original Profile
                    if let profile = originalProfile {
                        DataCard(
                            title: "1. Original Profile",
                            icon: "person.text.rectangle",
                            content: "Name: \(profile.fullName)\nRole: \(profile.role)\nClearance: Level \(profile.clearanceLevel)"
                        )
                    }
                    
                    // 2. Encrypted CBOR Payload
                    if let data = encryptedData {
                        DataCard(
                            title: "2. Encrypted CBOR Data (AES-GCM)",
                            icon: "shippingbox.fill",
                            content: data.base64EncodedString()
                        )
                    }
                    
                    // 3. Decrypted Profile
                    if let profile = decryptedProfile {
                        DataCard(
                            title: "3. Decrypted & Decoded Profile",
                            icon: "checkmark.seal.fill",
                            content: "Name: \(profile.fullName)\nRole: \(profile.role)\nClearance: Level \(profile.clearanceLevel)",
                            borderColor: .green
                        )
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Error Display
                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationTitle("Vault")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Cryptography Flows
    
    private func generateAndEncryptProfile() {
        errorMessage = nil
        decryptedProfile = nil // Reset decryption state
        
        // 1. Create a mock profile
        let profile = DigitalIDProfile(
            fullName: "Kelvin",
            role: "Software Engineer",
            clearanceLevel: 4
        )
        originalProfile = profile
        
        do {
            // 2. Encode to CBOR payload
            let cborBytes = try cborManager.encodeProfile(profile)
            let cborData = Data(cborBytes)
            
            // 3. Encrypt the CBOR data using CryptoKit and Keychain
            let sealedData = try cryptoManager.encrypt(data: cborData)
            
            withAnimation {
                self.encryptedData = sealedData
            }
            
        } catch {
            self.errorMessage = "Encryption Failed: \(error.localizedDescription)"
        }
    }
    
    private func decryptAndDecodeProfile() {
        guard let sealedData = encryptedData else { return }
        errorMessage = nil
        
        do {
            // 1. Decrypt the sealed data back to raw CBOR bytes
            let decryptedData = try cryptoManager.decrypt(combinedData: sealedData)
            let cborBytes = [UInt8](decryptedData)
            
            // 2. Decode the CBOR bytes back into the DigitalIDProfile
            let profile = try cborManager.decodeProfile(from: cborBytes)
            
            withAnimation {
                self.decryptedProfile = profile
            }
            
        } catch {
            self.errorMessage = "Decryption Failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Reusable UI Component
struct DataCard: View {
    let title: String
    let icon: String
    let content: String
    var borderColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(borderColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(content)
                .font(.system(.body, design: .monospaced))
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    VaultDashboardView()
}
