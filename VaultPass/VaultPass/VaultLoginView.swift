//
//  VaultLoginView.swift
//  VaultPass
//
//  Created by kobby on 05/08/2026.
//


import SwiftUI
import SharedSecurityKit

struct VaultLoginView: View {
    // MARK: - State & Managers
    @State private var jwtManager = JWTManager()
    
    // UI State
    @State private var employeeName: String = "Kelvin"
    @State private var clearanceLevel: String = "3"
    @State private var isAuthenticating: Bool = false
    @State private var generatedToken: String?
    @State private var errorMessage: String?
    @State private var isVaultUnlocked: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                
                // MARK: - Header
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(isVaultUnlocked ? .green : .blue)
                    .padding(.top, 40)
                
                Text("VaultPass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Secure Digital ID Wallet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider().padding(.horizontal)
                
                // MARK: - Mock Login Form
                if !isVaultUnlocked {
                    VStack(spacing: 15) {
                        TextField("Employee Name", text: $employeeName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                        
                        TextField("Clearance Level (e.g., 1-5)", text: $clearanceLevel)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            generateMockToken()
                        }) {
                            Text("1. Generate JWT (Login)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Token Display & Verification
                if let token = generatedToken, !isVaultUnlocked {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active JWT Token:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(token)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(3)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        
                        Button(action: {
                            verifyAndUnlockVault(with: token)
                        }) {
                            HStack {
                                if isAuthenticating {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("2. Verify & Unlock Vault")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isAuthenticating)
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Success State
                if isVaultUnlocked {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                        
                        Text("Vault Unlocked")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("JWT Signature Verified. Local cryptography keys are now accessible.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: VaultDashboardView()) {
                            Text("Enter Vault")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                }
                
                // MARK: - Error Handling
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
    }
    
    // MARK: - Authentication Flows
    
    private func generateMockToken() {
        errorMessage = nil
        
        let profile = DigitalIDProfile(
            fullName: employeeName.isEmpty ? "Unknown" : employeeName,
            role: "Software Engineer",
            clearanceLevel: Int(clearanceLevel) ?? 1
        )
        
        do {
            // Generate and sign the JWT locally
            let token = try jwtManager.generateToken(for: profile)
            
            withAnimation {
                self.generatedToken = token
            }
        } catch {
            self.errorMessage = "Failed to generate token: \(error.localizedDescription)"
        }
    }
    
    private func verifyAndUnlockVault(with token: String) {
        isAuthenticating = true
        errorMessage = nil
        
        // Simulate a slight network/processing delay for realism
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                // Decode and verify the signature
                let _ = try jwtManager.verifyToken(token)
                
                withAnimation {
                    self.isVaultUnlocked = true
                    self.isAuthenticating = false
                }
            } catch {
                withAnimation {
                    self.errorMessage = "Token Verification Failed: \(error.localizedDescription)"
                    self.isAuthenticating = false
                }
            }
        }
    }
}

#Preview {
    VaultLoginView()
}
