//
//  HardwareStatusDashboard.swift
//  AccessGuard
//
//  Created by kobby on 04/08/2026.
//


import SwiftUI

struct HardwareStatusDashboard: View {
    // Inject both hardware managers
    @State private var nfcManager = NFCManager()
    @State private var bleManager = BLEManager()
    
    // State to hold the scanned badge ID or error messages
    @State private var scannedBadgeID: String?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // MARK: - Hardware Status Cards
                    HStack(spacing: 20) {
                        StatusCard(
                            title: "NFC Reader",
                            systemImage: "wave.3.right.circle.fill",
                            isActive: nfcManager.isScanning,
                            activeColor: .blue
                        )
                        
                        StatusCard(
                            title: "BLE Proximity",
                            systemImage: "antenna.radiowaves.left.and.right",
                            isActive: bleManager.isScanning,
                            activeColor: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // MARK: - BLE Proximity Doors Area
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Nearby Secure Doors")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if bleManager.nearbyDoors.isEmpty {
                            Text(bleManager.isBluetoothPoweredOn ? "Scanning for doors..." : "Bluetooth is disabled.")
                                .italic()
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(bleManager.nearbyDoors) { door in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(door.name)
                                            .font(.headline)
                                        Text("Signal: \(door.signalStrength) dBm")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Unlock Door button becomes active when in range
                                    Button(action: {
                                        unlock(door: door)
                                    }) {
                                        Text("Unlock Door")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // MARK: - Scan Results Area
                    VStack(spacing: 15) {
                        Text("Last Scanned Badge")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let badgeID = scannedBadgeID {
                            Text(badgeID)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        } else {
                            Text("No badge scanned yet.")
                                .italic()
                                .foregroundColor(.gray)
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.callout)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                    
                    // MARK: - Action Button
                    Button(action: {
                        triggerNFCScan()
                    }) {
                        Label(
                            nfcManager.isScanning ? "Scanning..." : "Scan Employee Badge",
                            systemImage: "sensor.tag.radiowaves.forward"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nfcManager.isScanning ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(nfcManager.isScanning)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top)
            }
            .navigationTitle("AccessGuard")
        }
    }
    
    // MARK: - Action Handlers
    
    private func triggerNFCScan() {
        scannedBadgeID = nil
        errorMessage = nil
        
        Task {
            do {
                let badgeData = try await nfcManager.scanBadge()
                self.scannedBadgeID = badgeData
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func unlock(door: SecureDoor) {
        // In a real application, this would trigger a network request or write a characteristic to the BLE peripheral to unlock it.
        print("Unlocking \(door.name)...")
    }
}

// MARK: - Reusable UI Components

struct StatusCard: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let activeColor: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(isActive ? activeColor : .gray)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(isActive ? "Active" : "Idle")
                .font(.caption)
                .foregroundColor(isActive ? activeColor : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isActive ? activeColor : Color.gray).opacity(0.2))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HardwareStatusDashboard()
}
