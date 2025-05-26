//
//  Camera.swift
//  keepsake
//
//  Enhanced version with wide/ultrawide camera switching and ultrawide zoom support
//

import AVFoundation
import CoreImage
import UIKit
import os.log

class Camera: NSObject {
	private let captureSession = AVCaptureSession()
	private var isCaptureSessionConfigured = false
	private var deviceInput: AVCaptureDeviceInput?
	private var photoOutput: AVCapturePhotoOutput?
	private var videoOutput: AVCaptureVideoDataOutput?
	private var sessionQueue: DispatchQueue!
	
	var maxZoomFactor: CGFloat? {
		captureDevice?.activeFormat.videoMaxZoomFactor
	}
	
	var useFlash = false
	
	// Current camera position (front/back)
	private var currentCameraPosition: AVCaptureDevice.Position = .back
	
	private var allCaptureDevices: [AVCaptureDevice] {
		AVCaptureDevice.DiscoverySession(
			deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
			mediaType: .video,
			position: .unspecified
		).devices
	}
	
	private var frontCaptureDevices: [AVCaptureDevice] {
		allCaptureDevices.filter { $0.position == .front }
	}
	
	private var backCaptureDevices: [AVCaptureDevice] {
		allCaptureDevices.filter { $0.position == .back }
	}
	
	// Get the wide camera for current position
	private var wideCaptureDevice: AVCaptureDevice? {
		let devices = currentCameraPosition == .back ? backCaptureDevices : frontCaptureDevices
		return devices.first { $0.deviceType == .builtInWideAngleCamera }
	}
	
	// Get the ultrawide camera for current position
	private var ultraWideCaptureDevice: AVCaptureDevice? {
		let devices = currentCameraPosition == .back ? backCaptureDevices : frontCaptureDevices
		return devices.first { $0.deviceType == .builtInUltraWideCamera }
	}
	
	private var captureDevices: [AVCaptureDevice] {
		var devices = [AVCaptureDevice]()
#if os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
		devices += allCaptureDevices
#else
		// Add back cameras
		if let backWide = backCaptureDevices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
			devices.append(backWide)
		}
		if let backUltraWide = backCaptureDevices.first(where: { $0.deviceType == .builtInUltraWideCamera }) {
			devices.append(backUltraWide)
		}
		
		// Add front cameras
		if let frontWide = frontCaptureDevices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
			devices.append(frontWide)
		}
		if let frontUltraWide = frontCaptureDevices.first(where: { $0.deviceType == .builtInUltraWideCamera }) {
			devices.append(frontUltraWide)
		}
#endif
		return devices
	}
	
	private var availableCaptureDevices: [AVCaptureDevice] {
		captureDevices
			.filter( { $0.isConnected } )
			.filter( { !$0.isSuspended } )
	}
	
	private var captureDevice: AVCaptureDevice? {
		didSet {
			guard let captureDevice = captureDevice else { return }
			logger.debug("Using capture device: \(captureDevice.localizedName)")
			sessionQueue.async {
				self.updateSessionForCaptureDevice(captureDevice)
			}
		}
	}
	
	var isRunning: Bool {
		captureSession.isRunning
	}
	
	var isUsingFrontCaptureDevice: Bool {
		guard let captureDevice = captureDevice else { return false }
		return frontCaptureDevices.contains(captureDevice)
	}
	
	var isUsingBackCaptureDevice: Bool {
		guard let captureDevice = captureDevice else { return false }
		return backCaptureDevices.contains(captureDevice)
	}
	
	var isUsingUltraWideCamera: Bool {
		guard let captureDevice = captureDevice else { return false }
		return captureDevice.deviceType == .builtInUltraWideCamera
	}
	
	var isUsingWideCamera: Bool {
		guard let captureDevice = captureDevice else { return false }
		return captureDevice.deviceType == .builtInWideAngleCamera
	}
	
	private var addToPhotoStream: ((AVCapturePhoto) -> Void)?
	private var addToPreviewStream: ((CIImage) -> Void)?
	
	var isPreviewPaused = false
	
	lazy var previewStream: AsyncStream<CIImage> = {
		AsyncStream { continuation in
			addToPreviewStream = { ciImage in
				if !self.isPreviewPaused {
					continuation.yield(ciImage)
				}
			}
		}
	}()
	
	lazy var photoStream: AsyncStream<AVCapturePhoto> = {
		AsyncStream { continuation in
			addToPhotoStream = { photo in
				continuation.yield(photo)
			}
		}
	}()
	
	override init() {
		super.init()
		initialize()
	}
	
	private func initialize() {
		sessionQueue = DispatchQueue(label: "session queue")
		
		// Start with the wide camera
		captureDevice = wideCaptureDevice ?? availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
		
		UIDevice.current.beginGeneratingDeviceOrientationNotifications()
		NotificationCenter.default.addObserver(self, selector: #selector(updateForDeviceOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
	}
	
	// MARK: - Camera Switching Methods
	
	func switchToUltraWideCamera() {
		guard let ultraWideDevice = ultraWideCaptureDevice else {
			logger.debug("Ultra-wide camera not available for current position")
			return
		}
		
		if captureDevice != ultraWideDevice {
			captureDevice = ultraWideDevice
		}
	}
	
	func switchToWideCamera() {
		guard let wideDevice = wideCaptureDevice else {
			logger.debug("Wide camera not available for current position")
			return
		}
		
		if captureDevice != wideDevice {
			captureDevice = wideDevice
		}
	}
	
	func setZoomFactor(_ factor: CGFloat, animated: Bool = true, rate: Float = 2.0) {
		guard let device = captureDevice else { return }
		
		let clampedZoomFactor: CGFloat
		if isUsingUltraWideCamera {
			// Ultra-wide camera: Allow zoom from 1.0 to 1.8 (equivalent to 0.5x to 0.9x)
			clampedZoomFactor = max(1.0, min(factor, 1.8))
		} else {
			// Wide camera: 1.0 to 10.0
			clampedZoomFactor = max(1.0, min(factor, 10.0))
		}
		
		sessionQueue.async {
			do {
				try device.lockForConfiguration()
				device.videoZoomFactor = clampedZoomFactor
				device.unlockForConfiguration()
			} catch {
				logger.error("Failed to set zoom factor: \(error.localizedDescription)")
			}
		}
	}
	
	// Method to manually switch to ultrawide and set appropriate zoom
	func switchToUltraWideWithZoom(_ targetZoomLevel: CGFloat) {
		switchToUltraWideCamera()
		// Convert UI zoom level (0.5-0.9) to device zoom factor (1.0-1.8)
		let deviceZoomFactor = targetZoomLevel * 2.0
		sessionQueue.async {
			guard let device = self.captureDevice else { return }
			do {
				try device.lockForConfiguration()
				device.videoZoomFactor = max(1.0, min(deviceZoomFactor, 1.8))
				device.unlockForConfiguration()
			} catch {
				logger.error("Failed to set zoom factor on ultra-wide: \(error.localizedDescription)")
			}
		}
	}
	
	// Method to manually switch to wide and set zoom
	func switchToWideWithZoom(_ targetZoomLevel: CGFloat) {
		switchToWideCamera()
		let clampedZoom = max(1.0, min(targetZoomLevel, 10.0))
		sessionQueue.async {
			guard let device = self.captureDevice else { return }
			do {
				try device.lockForConfiguration()
				device.videoZoomFactor = clampedZoom
				device.unlockForConfiguration()
			} catch {
				logger.error("Failed to set zoom factor on wide: \(error.localizedDescription)")
			}
		}
	}
	
	// Helper method to convert device zoom factor to UI zoom level
	func getUIZoomLevel() -> CGFloat {
		guard let device = captureDevice else { return 1.0 }
		let deviceZoom = device.videoZoomFactor
		
		if isUsingUltraWideCamera {
			// Convert device zoom (1.0-1.8) to UI zoom (0.5-0.9)
			return deviceZoom / 2.0
		} else {
			// Wide camera zoom is 1:1
			return deviceZoom
		}
	}
	
	private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
		var success = false
		
		self.captureSession.beginConfiguration()
		
		defer {
			self.captureSession.commitConfiguration()
			completionHandler(success)
		}
		
		guard
			let captureDevice = captureDevice,
			let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
		else {
			logger.error("Failed to obtain video input.")
			return
		}
		
		let photoOutput = AVCapturePhotoOutput()
		
		captureSession.sessionPreset = AVCaptureSession.Preset.photo
		
		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
		
		guard captureSession.canAddInput(deviceInput) else {
			logger.error("Unable to add device input to capture session.")
			return
		}
		guard captureSession.canAddOutput(photoOutput) else {
			logger.error("Unable to add photo output to capture session.")
			return
		}
		guard captureSession.canAddOutput(videoOutput) else {
			logger.error("Unable to add video output to capture session.")
			return
		}
		
		captureSession.addInput(deviceInput)
		captureSession.addOutput(photoOutput)
		captureSession.addOutput(videoOutput)
		
		self.deviceInput = deviceInput
		self.photoOutput = photoOutput
		self.videoOutput = videoOutput
		
		photoOutput.maxPhotoQualityPrioritization = .quality
		
		updateVideoOutputConnection()
		
		isCaptureSessionConfigured = true
		
		success = true
	}
	
	private func checkAuthorization() async -> Bool {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			logger.debug("Camera access authorized.")
			return true
		case .notDetermined:
			logger.debug("Camera access not determined.")
			sessionQueue.suspend()
			let status = await AVCaptureDevice.requestAccess(for: .video)
			sessionQueue.resume()
			return status
		case .denied:
			logger.debug("Camera access denied.")
			return false
		case .restricted:
			logger.debug("Camera library access restricted.")
			return false
		@unknown default:
			return false
		}
	}
	
	private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
		guard let validDevice = device else { return nil }
		do {
			return try AVCaptureDeviceInput(device: validDevice)
		} catch let error {
			logger.error("Error getting capture device input: \(error.localizedDescription)")
			return nil
		}
	}
	
	private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
		guard isCaptureSessionConfigured else { return }
		
		captureSession.beginConfiguration()
		defer { captureSession.commitConfiguration() }
		
		for input in captureSession.inputs {
			if let deviceInput = input as? AVCaptureDeviceInput {
				captureSession.removeInput(deviceInput)
			}
		}
		
		if let deviceInput = deviceInputFor(device: captureDevice) {
			if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
				captureSession.addInput(deviceInput)
				self.deviceInput = deviceInput
			}
		}
		
		updateVideoOutputConnection()
	}
	
	private func updateVideoOutputConnection() {
		if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video) {
			if videoOutputConnection.isVideoMirroringSupported {
				videoOutputConnection.isVideoMirrored = isUsingFrontCaptureDevice
			}
		}
	}
	
	func start() async {
		let authorized = await checkAuthorization()
		guard authorized else {
			logger.error("Camera access was not authorized.")
			return
		}
		
		if isCaptureSessionConfigured {
			if !captureSession.isRunning {
				sessionQueue.async { [self] in
					self.captureSession.startRunning()
				}
			}
			return
		}
		
		sessionQueue.async { [self] in
			self.configureCaptureSession { success in
				guard success else { return }
				self.captureSession.startRunning()
			}
		}
	}
	
	func stop() {
		guard isCaptureSessionConfigured else { return }
		
		if captureSession.isRunning {
			sessionQueue.async {
				self.captureSession.stopRunning()
			}
		}
	}
	
	func switchCaptureDevice() {
		// Switch between front and back camera positions
		currentCameraPosition = currentCameraPosition == .back ? .front : .back
		
		// Determine which camera to use based on current state
		let targetDevice: AVCaptureDevice?
		
		if isUsingUltraWideCamera {
			// Try to keep ultra-wide if available on the new position
			targetDevice = ultraWideCaptureDevice ?? wideCaptureDevice
		} else {
			// Default to wide camera
			targetDevice = wideCaptureDevice
		}
		
		if let device = targetDevice {
			captureDevice = device
		} else {
			// Fallback to any available camera
			captureDevice = availableCaptureDevices.first ?? AVCaptureDevice.default(for: .video)
		}
	}
	
	private var deviceOrientation: UIDeviceOrientation {
		var orientation = UIDevice.current.orientation
		if orientation == UIDeviceOrientation.unknown {
			orientation = UIScreen.main.orientation
		}
		return orientation
	}
	
	@objc
	func updateForDeviceOrientation() {
		//TODO: Figure out if we need this for anything.
	}
	
	func takePhoto() {
		guard let photoOutput = self.photoOutput else { return }
		
		sessionQueue.async {
			var photoSettings = AVCapturePhotoSettings()
			
			if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
				photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
			}
			
			let isFlashAvailable = self.deviceInput?.device.isFlashAvailable ?? false
			photoSettings.flashMode = isFlashAvailable ? (self.useFlash ? .on : .off) : .off
			
			photoSettings.isHighResolutionPhotoEnabled = photoOutput.isHighResolutionCaptureEnabled
			
			if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
				photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
			}
			photoSettings.photoQualityPrioritization = .quality
			
			if let photoOutputVideoConnection = photoOutput.connection(with: .video) {
				if photoOutputVideoConnection.isVideoOrientationSupported {
					photoOutputVideoConnection.videoOrientation = .portrait
				}
			}
			
			photoOutput.capturePhoto(with: photoSettings, delegate: self)
		}
	}
	
	private func videoOrientationFor(_ deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
		switch deviceOrientation {
		case .portrait:
			return .portrait
		case .portraitUpsideDown:
			return .portraitUpsideDown
		case .landscapeLeft:
			return .landscapeRight
		case .landscapeRight:
			return .landscapeLeft
		default:
			return .portrait
		}
	}
}

extension Camera: AVCapturePhotoCaptureDelegate {
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		if let error = error {
			logger.error("Error capturing photo: \(error.localizedDescription)")
			return
		}
		
		addToPhotoStream?(photo)
	}
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
		
		if connection.isVideoOrientationSupported {
			connection.videoOrientation = .portrait
		}
		
		addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
	}
}

fileprivate extension UIScreen {
	var orientation: UIDeviceOrientation {
		let point = coordinateSpace.convert(CGPoint.zero, to: fixedCoordinateSpace)
		if point == CGPoint.zero {
			return .portrait
		} else if point.x != 0 && point.y != 0 {
			return .portraitUpsideDown
		} else if point.x == 0 && point.y != 0 {
			return .landscapeRight
		} else if point.x != 0 && point.y == 0 {
			return .landscapeLeft
		} else {
			return .unknown
		}
	}
}

fileprivate let logger = Logger(subsystem: "com.apple.swiftplaygroundscontent.capturingphotos", category: "Camera")
