//
//  BothSidesRecorder.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import Foundation
import AVFoundation

final class BothSidesRecorder {

    var isRunning                     = false
    private var assetWriter           : AVAssetWriter?
    private var assetWriterVideoInput : AVAssetWriterInput?
    private var assetWriterAudioInput : AVAssetWriterInput?
    private var videoTransform        : CGAffineTransform
    private var videoSettings         : [String: Any]
    private var audioSettings         : [String: Any]


    init(audioSettings: [String: Any]? = nil, videoSettings: [String: Any]? = nil, videoTransform: CGAffineTransform? = nil) {
        self.audioSettings = audioSettings ?? [String: Any]()
        self.videoSettings = videoSettings ?? [String: Any]()
        self.videoTransform = videoTransform ?? CGAffineTransform()
    }

    func startRecording() {

        isRunning = true

        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }

        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)

        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)

        assetWriterVideoInput.expectsMediaDataInRealTime = true

        assetWriterVideoInput.transform = videoTransform
        assetWriter.add(assetWriterVideoInput)

        self.assetWriter = assetWriter
        self.assetWriterAudioInput = assetWriterAudioInput
        self.assetWriterVideoInput = assetWriterVideoInput
    }

    func stopRecording(completion: @escaping (URL) -> Void) {

        isRunning = false
        guard let assetWriter = assetWriter else { return }

        self.assetWriter = nil

        assetWriter.finishWriting { completion(assetWriter.outputURL) }
    }

    func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard  let assetWriter = assetWriter else { return }
        
        switch assetWriter.status {
        case .unknown:
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        case .writing:
            if let input = assetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        default: break
        }
    }

    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard let assetWriter = assetWriter,
            assetWriter.status == .writing,
            let input = assetWriterAudioInput,
            input.isReadyForMoreMediaData else {
                return
        }
        input.append(sampleBuffer)
    }
}
