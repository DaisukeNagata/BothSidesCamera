//
//  BothSidesMultiCamViewModel.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import AVFoundation


final class BothSidesMultiCamViewModel: NSObject {

    var aModel  : BothSidesMultiCamSessionModel?
    var session = AVCaptureMultiCamSession()
    let backCameraVideoDataOutput = AVCaptureVideoDataOutput()

    var frontDeviceInput                       : AVCaptureDeviceInput?
    var backDeviceInput                        : AVCaptureDeviceInput?
    var backCamera                             : AVCaptureDevice?

    private var microphoneDeviceInput          : AVCaptureDeviceInput?
    private let frontCameraVideoDataOutput     = AVCaptureVideoDataOutput()
    private let backMicrophoneAudioDataOutput  = AVCaptureAudioDataOutput()
    private let frontMicrophoneAudioDataOutput = AVCaptureAudioDataOutput()
    private let sessionQueue                   = DispatchQueue(label: "session queue")
    private let dataOutputQueue                = DispatchQueue(label: "data output queue")


    override init() {
        aModel = BothSidesMultiCamSessionModel()
        super.init()
        dataSet()
    }

    func dataSet() {
        aModel?.dataOutput(backdataOutput: backCameraVideoDataOutput,
                              frontDataOutput: frontCameraVideoDataOutput,
                              backicrophoneDataOutput: backMicrophoneAudioDataOutput,
                              fronticrophoneDataOutput: frontMicrophoneAudioDataOutput)
    }

    func configureBackCamera(_ backCameraVideoPreviewLayer: AVCaptureVideoPreviewLayer?,deviceType :AVCaptureDevice.DeviceType) {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        backCamera = AVCaptureDevice.default(deviceType, for: .video, position: .back)
        guard let backCamera = backCamera else {
            print("BothSidesMultiCamViewModel_backCamera")
            return
        }
        
        do {
            backDeviceInput = try AVCaptureDeviceInput(device: backCamera)

            guard let backCameraDeviceInput = backDeviceInput,
                session.canAddInput(backCameraDeviceInput) else {
                    print("AVCaptureMultiCamViewModel_backCameraDeviceInput")
                    return
            }
    
            session.addInputWithNoConnections(backCameraDeviceInput)
        } catch {
            return
        }

        guard let backCameraDeviceInput = backDeviceInput,
            let backCameraVideoPort = backCameraDeviceInput.ports(for: .video,
                                                                  sourceDeviceType: backCamera.deviceType,
                                                                  sourceDevicePosition: backCamera.position).first else {
                                                                    print("AVCaptureMultiCamViewModel_backCameraVideoPort")
                                                                    return
        }

        guard session.canAddOutput(backCameraVideoDataOutput) else {
            print("AVCaptureMultiCamViewModel_session.canAddOutput")
            return
        }

        session.addOutputWithNoConnections(backCameraVideoDataOutput)
        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        backCameraVideoDataOutput.setSampleBufferDelegate(aModel, queue: dataOutputQueue)

        let backCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort], output: backCameraVideoDataOutput)
        guard session.canAddConnection(backCameraVideoDataOutputConnection) else {
            print("AVCaptureMultiCamViewModel_session.canAddConnection")
            return
        }

        session.addConnection(backCameraVideoDataOutputConnection)
        backCameraVideoDataOutputConnection.videoOrientation = .portrait

        guard let backCameraVideoPreviewLayer = backCameraVideoPreviewLayer else {
            print("AVCaptureMultiCamViewModel_backCameraVideoPreviewLayer")
            return
        }

        let backCameraVideoPreviewLayerConnection = AVCaptureConnection(inputPort: backCameraVideoPort, videoPreviewLayer: backCameraVideoPreviewLayer)
        guard session.canAddConnection(backCameraVideoPreviewLayerConnection) else {
            print("AVCaptureMultiCamViewModel_session.canAddConnection")
            return
        }
        session.addConnection(backCameraVideoPreviewLayerConnection)
    }

    func configureFrontCamera(_ frontCameraVideoPreviewLayer: AVCaptureVideoPreviewLayer?, deviceType :AVCaptureDevice.DeviceType) {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        guard let frontCamera = AVCaptureDevice.default(deviceType, for: .video, position: .front) else {
            print("AVCaptureMultiCamViewModel_frontCamera")
            return
        }

        do {
            frontDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            guard let frontCameraDeviceInput = frontDeviceInput,
                session.canAddInput(frontCameraDeviceInput) else {
                    print("AVCaptureMultiCamViewModel_frontCameraDeviceInput")
                    return
            }
            session.addInputWithNoConnections(frontCameraDeviceInput)
        } catch {
            return
        }

        guard let frontCameraDeviceInput = frontDeviceInput,
            let frontCameraVideoPort = frontCameraDeviceInput.ports(for: .video,
                                                                    sourceDeviceType: frontCamera.deviceType,
                                                                    sourceDevicePosition: frontCamera.position).first else {
                                                                        print("AVCaptureMultiCamViewModel_frontCameraVideoPort")
                                                                        return
        }
        guard session.canAddOutput(frontCameraVideoDataOutput) else {
            print("AVCaptureMultiCamViewModel_session.canAddOutput")
            return
        }

        session.addOutputWithNoConnections(frontCameraVideoDataOutput)
        frontCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        frontCameraVideoDataOutput.setSampleBufferDelegate(aModel, queue: dataOutputQueue)

        let frontCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort], output: frontCameraVideoDataOutput)
        guard session.canAddConnection(frontCameraVideoDataOutputConnection) else {
            print("AVCaptureMultiCamViewModel_session.canAddConnection")
            return
        }

        session.addConnection(frontCameraVideoDataOutputConnection)
        frontCameraVideoDataOutputConnection.videoOrientation = .portrait
        frontCameraVideoDataOutputConnection.automaticallyAdjustsVideoMirroring = false
        frontCameraVideoDataOutputConnection.isVideoMirrored = true

        guard let frontCameraVideoPreviewLayer = frontCameraVideoPreviewLayer else {
            print("AVCaptureMultiCamViewModel_frontCameraVideoPreviewLayer")
            return
        }

        let frontCameraVideoPreviewLayerConnection = AVCaptureConnection(inputPort: frontCameraVideoPort, videoPreviewLayer: frontCameraVideoPreviewLayer)
        guard session.canAddConnection(frontCameraVideoPreviewLayerConnection) else {
            print("AVCaptureMultiCamViewModel_session.canAddConnection")
            return
        }

        session.addConnection(frontCameraVideoPreviewLayerConnection)
        frontCameraVideoPreviewLayerConnection.automaticallyAdjustsVideoMirroring = false
        frontCameraVideoPreviewLayerConnection.isVideoMirrored = true
    }

    func configureMicrophone() {

        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            print("AVCaptureMultiCamViewModel_microphone")
            return
        }

        do {
            self.microphoneDeviceInput = try AVCaptureDeviceInput(device: microphone)
            
            guard let microphoneDeviceInput = microphoneDeviceInput,
                session.canAddInput(microphoneDeviceInput) else {
                    print("AVCaptureMultiCamViewModel_microphoneDeviceInput")
                    return
            }
            session.addInputWithNoConnections(microphoneDeviceInput)
        } catch {
            return
        }
        guard let microphoneDeviceInput = microphoneDeviceInput,
            let backMicrophonePort = microphoneDeviceInput.ports(for: .audio,
                                                                 sourceDeviceType: microphone.deviceType,
                                                                 sourceDevicePosition: .back).first else {
                                                                    print("AVCaptureMultiCamViewModel_microphoneDeviceInput")
                                                                    return
        }

        guard let frontMicrophonePort = microphoneDeviceInput.ports(for: .audio,
                                                                    sourceDeviceType: microphone.deviceType,
                                                                    sourceDevicePosition: .front).first else {
                                                                    print("AVCaptureMultiCamViewModel_frontMicrophonePort")
                                                                    return
                                                                        
        }

        guard session.canAddOutput(backMicrophoneAudioDataOutput) else {
            print("AVCaptureMultiCamViewModel_session.canAddOutput")
            return
        }

        session.addOutputWithNoConnections(backMicrophoneAudioDataOutput)
        backMicrophoneAudioDataOutput.setSampleBufferDelegate(aModel, queue: dataOutputQueue)

        guard session.canAddOutput(frontMicrophoneAudioDataOutput) else {
            print("AVCaptureMultiCamViewModel_session.canAddOutput")
            return
        }

        session.addOutputWithNoConnections(frontMicrophoneAudioDataOutput)
        frontMicrophoneAudioDataOutput.setSampleBufferDelegate(aModel, queue: dataOutputQueue)

        let backMicrophoneAudioDataOutputConnection = AVCaptureConnection(inputPorts: [backMicrophonePort], output: backMicrophoneAudioDataOutput)
        guard session.canAddConnection(backMicrophoneAudioDataOutputConnection) else {
            print("AVCaptureMultiCamViewModel_session.canAddConnection")
            return
        }

        session.addConnection(backMicrophoneAudioDataOutputConnection)

        let frontMicrophoneAudioDataOutputConnection = AVCaptureConnection(inputPorts: [frontMicrophonePort], output: frontMicrophoneAudioDataOutput)
        guard session.canAddConnection(frontMicrophoneAudioDataOutputConnection) else {
            print("AVCaptureMultiCamViewModel_session.canAddConnection")
            return
        }

        session.addConnection(frontMicrophoneAudioDataOutputConnection)
    }
}
