//
//  PhotoLibrary.swift
//  keepsake
//
//  Created by Ryan Hangralim on 17/05/25.
//

import Photos
import os.log

class PhotoLibrary {

    static func checkAuthorization() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            logger.debug("Photo library access authorized.")
            return true
        case .notDetermined:
            logger.debug("Photo library access not determined.")
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
        case .denied:
            logger.debug("Photo library access denied.")
            return false
        case .limited:
            logger.debug("Photo library access limited.")
            return false
        case .restricted:
            logger.debug("Photo library access restricted.")
            return false
        @unknown default:
            return false
        }
    }
}

fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "PhotoLibrary")
