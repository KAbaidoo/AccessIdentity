//
//  BLEManager.swift
//  AccessGuard
//
//  Created by kobby on 04/08/2026.
//


import Foundation
import CoreBluetooth
import Observation

@Observable
class BLEManager: NSObject, CBCentralManagerDelegate {
    
    // MARK: - UI State
    var isBluetoothPoweredOn = false
    var isScanning = false
    var nearbyDoors: [SecureDoor] = []
    
    // MARK: - CoreBluetooth Properties
    private var centralManager: CBCentralManager!
    
    // A mock Service UUID that your "secure doors" would broadcast.
    // In production, you filter by this exact UUID.
    private let secureDoorServiceUUID = CBUUID(string: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")
    
    override init() {
        super.init()
        // Initializing on the main queue ensures our @Observable properties 
        // update the SwiftUI views cleanly without thread crossing.
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // MARK: - Scanning Logic
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        
        // Clear previous discoveries
        nearbyDoors.removeAll()
        isScanning = true
        
        // To strictly filter for your hardware, pass [secureDoorServiceUUID] instead of nil
        // For testing purposes without custom hardware, we can pass nil to see all nearby devices
        centralManager.scanForPeripherals(
            withServices: [secureDoorServiceUUID], 
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    // MARK: - CBCentralManagerDelegate Requirements
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothPoweredOn = (central.state == .poweredOn)
        
        if isBluetoothPoweredOn {
            startScanning()
        } else {
            stopScanning()
            nearbyDoors.removeAll()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // We convert the RSSI (signal strength) to a positive distance metric for UI purposes
        let signalStrength = RSSI.intValue
        
        // Filter out devices with extremely weak signals (too far away)
        guard signalStrength > -80 else { return }
        
        let doorName = peripheral.name ?? "Secure Door (\(peripheral.identifier.uuidString.prefix(4)))"
        
        let discoveredDoor = SecureDoor(
            id: peripheral.identifier,
            name: doorName,
            signalStrength: signalStrength
        )
        
        // Update our array, replacing the door if it already exists to update its signal strength
        if let index = nearbyDoors.firstIndex(where: { $0.id == discoveredDoor.id }) {
            nearbyDoors[index] = discoveredDoor
        } else {
            nearbyDoors.append(discoveredDoor)
        }
    }
}

// MARK: - Supporting Models

/// Represents a discovered BLE beacon simulating a secure door
struct SecureDoor: Identifiable {
    let id: UUID
    let name: String
    let signalStrength: Int
}