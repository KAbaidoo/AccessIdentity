//
//  NFCManager.swift
//  AccessGuard
//
//  Created by kobby on 04/08/2026.
//

import Foundation
import CoreNFC
import Observation

@Observable
class NFCManager:NSObject, NFCNDEFReaderSessionDelegate {
    // Tracks the scanning state for SwiftUI to update the UI
        var isScanning = false
        
        // The active NFC session for parsing NDEF payload records
        private var session: NFCNDEFReaderSession?
        
        // The continuation that bridges the delegate to our async/await call
    private var scanContinuation: CheckedContinuation<
        String,
        Error
    >?
    
    enum NFCError: LocalizedError {
        case unavailable
        case invalidated(
            String
        )
        case invalidPayload
        
        var errorDescription: String? {
            switch self {
            case .unavailable: return "NFC scanning is not available on this device."
            case .invalidated(
                let message
            ): return message
            case .invalidPayload: return "The badge payload could not be read or is invalid."
            }
        }
    }
    
    /// Initiates the NFC scanning process and yields the result asynchronously.
    func scanBadge() async throws -> String {
        // 1. Ensure the device hardware supports NFC scanning
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCError.unavailable
        }
        
        // 2. Suspend the current task and store the continuation
        return try await withCheckedThrowingContinuation { continuation in
            self.scanContinuation = continuation
            self.isScanning = true
            
            // 3. Initialize the NFCNDEFReaderSession and set the delegate
            session = NFCNDEFReaderSession(
                delegate: self,
                queue: nil,
                invalidateAfterFirstRead: true
            )
            session?.alertMessage = "Hold the employee ID badge near the top of your iPhone."
            session?
                .begin()
        }
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate Requirements
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        // 4. Parse the NDEF payload records
        guard let firstMessage = messages.first,
              let firstRecord = firstMessage.records.first,
              let payloadString = String(
                data: firstRecord.payload,
                encoding: .utf8
              ) else {
            
            // Resume throwing an error if the payload cannot be parsed
            scanContinuation?
                .resume(
                    throwing: NFCError.invalidPayload
                )
            cleanupSession()
            return
        }
        
        // 5. Resume the continuation with the successfully extracted badge string
        scanContinuation?
            .resume(
                returning: payloadString
            )
        cleanupSession()
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: Error
    ) {
        // 6. Handle session invalidation (e.g., user pressed cancel, or a read error occurred)
        if let nfcError = error as? NFCReaderError, nfcError.code != .readerSessionInvalidationErrorUserCanceled {
            scanContinuation?
                .resume(
                    throwing: NFCError.invalidated(
                        error.localizedDescription
                    )
                )
        } else if let nfcError = error as? NFCReaderError, nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            scanContinuation?
                .resume(
                    throwing: NFCError.invalidated(
                        "Scanning canceled."
                    )
                )
        } else {
            scanContinuation?
                .resume(
                    throwing: NFCError.invalidated(
                        "An unknown error occurred."
                    )
                )
            }
            
            cleanupSession()
        }
        
        // MARK: - Helpers
        
        private func cleanupSession() {
            self.scanContinuation = nil
            self.isScanning = false
            self.session = nil
        }
    
}
