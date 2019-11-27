//
//  BothSidesMultiCamSessionModel.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

final class BothSidesMultiCamSessionModel: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate  {

    var normalizedPipFrame                       = CGRect.zero
    var movieRecorder                            : BothSidesRecorder?
    var pipDevicePosition                        : AVCaptureDevice.Position = .front
    var currentPiPSampleBuffer                   : CMSampleBuffer?
    var videoMixer                               = BothSidesMixer()

    var backCameraVideoDataOutput                : AVCaptureVideoDataOutput?
    private var videoTrackSourceFormatDescription: CMFormatDescription?
    private var frontCameraVideoDataOutput       : AVCaptureVideoDataOutput?
    private var backMicrophoneAudioDataOutput    : AVCaptureAudioDataOutput?
    private var frontMicrophoneAudioDataOutput   : AVCaptureAudioDataOutput?
    private var callBack                         = { () -> Void in }

    func dataOutput(backdataOutput : AVCaptureVideoDataOutput? = nil,
                    frontDataOutput: AVCaptureVideoDataOutput? = nil,
                    backicrophoneDataOutput: AVCaptureAudioDataOutput? = nil,
                    fronticrophoneDataOutput: AVCaptureAudioDataOutput? = nil) {
        backCameraVideoDataOutput = backdataOutput
        frontCameraVideoDataOutput = frontDataOutput
        backMicrophoneAudioDataOutput = backicrophoneDataOutput
        frontMicrophoneAudioDataOutput = fronticrophoneDataOutput

    }

    func recorderSet(bind: ()->()) {
        movieRecorder = BothSidesRecorder(audioSettings:  createAudioSettings(), videoSettings:  createVideoSettings(),videoTransform: createVideoTransform())
        bind()
    }

    private func processPiPSampleBuffer(_ pipSampleBuffer: CMSampleBuffer) {
        currentPiPSampleBuffer = pipSampleBuffer
    }

    private func processFullScreenSampleBuffer(_ fullScreenSampleBuffer: CMSampleBuffer) {
        guard let fullScreenPixelBuffer = CMSampleBufferGetImageBuffer(fullScreenSampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(fullScreenSampleBuffer) else {
                print("AVCaptureMultiCamSessionModel_formatDescription")
                return
        }

        guard let pipSampleBuffer = currentPiPSampleBuffer,
            let pipPixelBuffer = CMSampleBufferGetImageBuffer(pipSampleBuffer) else {
                print("AVCaptureMultiCamSessionModel_pipPixelBuffer")
                return
        }

        if !videoMixer.isPrepared { videoMixer.prepare(with: formatDescription, outputRetainedBufferCountHint: 3) }

        videoMixer.pipFrame = normalizedPipFrame
        guard let mixedPixelBuffer = videoMixer.mix(fullScreenPixelBuffer: fullScreenPixelBuffer,
                                                    pipPixelBuffer: pipPixelBuffer,
                                                    fullScreenPixelBufferIsFrontCamera: pipDevicePosition == .back) else {
                                                        print("AVCaptureMultiCamSessionModel_mixedPixelBuffer")
                                                        return
        }
        if let recorder = movieRecorder {
            guard let finalVideoSampleBuffer = createVideoSampleBufferWithPixelBuffer(mixedPixelBuffer,
                                                                                           presentationTime: CMSampleBufferGetPresentationTimeStamp(fullScreenSampleBuffer)) else {
                                                                                            print("AVCaptureMultiCamSessionModel_finalVideoSampleBuffer")
                                                                                            return
            }
            recorder.recordVideo(sampleBuffer: finalVideoSampleBuffer)
        }
    }

    private func createVideoSampleBufferWithPixelBuffer(_ pixelBuffer: CVPixelBuffer, presentationTime: CMTime) -> CMSampleBuffer? {
        guard let videoTrackSourceFormatDescription = videoTrackSourceFormatDescription else {
            print("AVCaptureMultiCamSessionModel_videoTrackSourceFormatDescription")
            return nil
        }
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: presentationTime, decodeTimeStamp: .invalid)
        let err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     dataReady: true,
                                                     makeDataReadyCallback: nil,
                                                     refcon: nil,
                                                     formatDescription: videoTrackSourceFormatDescription,
                                                     sampleTiming: &timingInfo,
                                                     sampleBufferOut: &sampleBuffer)

        if sampleBuffer == nil { print("sampleBuffer: \(err))") }
        return sampleBuffer
    }
}

extension BothSidesMultiCamSessionModel {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            processVideoSampleBuffer(sampleBuffer, fromOutput: videoDataOutput)
        } else if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            processsAudioSampleBuffer(sampleBuffer, fromOutput: audioDataOutput)
        }
    }

    private func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
        
        if videoTrackSourceFormatDescription == nil {
            videoTrackSourceFormatDescription = CMSampleBufferGetFormatDescription( sampleBuffer )
        }

        var fullScreenSampleBuffer: CMSampleBuffer?
        var pipSampleBuffer: CMSampleBuffer?

        if pipDevicePosition == .back && videoDataOutput == backCameraVideoDataOutput {
            pipSampleBuffer = sampleBuffer
        } else if pipDevicePosition == .back && videoDataOutput == frontCameraVideoDataOutput {
            fullScreenSampleBuffer = sampleBuffer
        } else if pipDevicePosition == .front && videoDataOutput == backCameraVideoDataOutput {
            fullScreenSampleBuffer = sampleBuffer
        } else if pipDevicePosition == .front && videoDataOutput == frontCameraVideoDataOutput {
            pipSampleBuffer = sampleBuffer
        }

        if let fullScreenSampleBuffer = fullScreenSampleBuffer {
            processFullScreenSampleBuffer(fullScreenSampleBuffer)
        }

        if let pipSampleBuffer = pipSampleBuffer {
            processPiPSampleBuffer(pipSampleBuffer)
        }
    }

    private func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput audioDataOutput: AVCaptureAudioDataOutput) {

        guard (pipDevicePosition == .back && audioDataOutput == backMicrophoneAudioDataOutput) ||
            (pipDevicePosition == .front && audioDataOutput == frontMicrophoneAudioDataOutput) else {
                // 常に通る
                return
        }

        if let recorder = movieRecorder {
            recorder.recordAudio(sampleBuffer: sampleBuffer)
        }
    }
}

extension BothSidesMultiCamSessionModel {
    func recordAction(completion: @escaping() -> Void){

        if movieRecorder?.isRunning == false {
            movieRecorder?.startRecording()
        } else {
            movieRecorder?.stopRecording { movieURL in
                self.saveMovieToPhotoLibrary(movieURL, call: completion )
            }
        }
    }

    private func saveMovieToPhotoLibrary(_ movieURL: URL, call: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: movieURL, options: options)
                }, completionHandler: { success, error in
                    if !success {
                        print("\(Bundle.main.applicationName) couldn't save the movie to your photo library: \(String(describing: error))")
                    } else {
                        self.callBack = call
                        self.callBack()
                        if FileManager.default.fileExists(atPath: movieURL.path) {
                            do {
                                try FileManager.default.removeItem(atPath: movieURL.path)
                            } catch {
                                print("Could not remove file at url: \(movieURL)")
                            }
                        }
                    }
                })
            }
        }
    }

    private func createAudioSettings() -> [String: NSObject]? {
        [backMicrophoneAudioDataOutput?.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject],
         frontMicrophoneAudioDataOutput?.recommendedAudioSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject]].compactMap{ settings in
            return settings
        }.last
    }

    private func createVideoSettings() -> [String: NSObject]? {
        [backCameraVideoDataOutput?.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject],
         frontCameraVideoDataOutput?.recommendedVideoSettingsForAssetWriter(writingTo: .mov) as? [String: NSObject]].compactMap{ settings in
            return settings
        }.last
    }

    private func createVideoTransform() -> CGAffineTransform? {
        guard let backCameraVideoConnection = backCameraVideoDataOutput?.connection(with: .video) else {
                print("AVCaptureMultiCamSessionModel_backCameraVideoConnection")
                return nil
        }

        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue) ?? .portraitUpsideDown
        let backCameraTransform = backCameraVideoConnection.videoOrientationTransform(relativeTo: videoOrientation)

        return backCameraTransform
    }
}
