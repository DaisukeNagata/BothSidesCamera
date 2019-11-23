//
//  BothSidesMixer.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import CoreMedia
import CoreVideo

final class BothSidesMixer {

    var pipFrame = CGRect.zero

    private(set) var isPrepared              = false
    private let metalDevice                  = MTLCreateSystemDefaultDevice()
    private var fullRangeVertexBuffer        : MTLBuffer?
    private var outputPixelBufferPool        : CVPixelBufferPool?
    private var textureCache                 : CVMetalTextureCache?
    private var computePipelineState         : MTLComputePipelineState?
    private(set) var inputFormatDescription  : CMFormatDescription?
    private(set) var outputFormatDescription : CMFormatDescription?

    private lazy var commandQueue            : MTLCommandQueue? = {
        guard let metalDevice = metalDevice else {
            print("BothSidesMixer_metalDevice")
            return nil
        }
        return metalDevice.makeCommandQueue()
    }()


    init() {
        do {
            let frameworkBundle = Bundle(for: type(of: self))
            let defaultLibrary = try metalDevice?.makeDefaultLibrary(bundle: frameworkBundle)
            guard let kernelFunction = defaultLibrary?.makeFunction(name: "reporterMixer") else {
                print("BothSidesMultiCamVideoMixer_kernelFunction")
                return
            }
            computePipelineState = try metalDevice?.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("\(error)")
        }
    }

    func prepare(with videoFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()

        (outputPixelBufferPool, _, outputFormatDescription) = allocateOutputBufferPool(with: videoFormatDescription,
                                                                                       outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil { return }

        inputFormatDescription = videoFormatDescription

        guard let metalDevice = metalDevice else { return }

        var metalTextureCache: CVMetalTextureCache?
        guard  CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache) == kCVReturnSuccess else { return }
        textureCache = metalTextureCache
        isPrepared = true
    }

    func reset() {
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        textureCache = nil
        isPrepared = false
    }

    struct MixerParameters {
        var pipPosition: SIMD2<Float>
        var pipSize: SIMD2<Float>
    }

    func mix(fullScreenPixelBuffer: CVPixelBuffer, pipPixelBuffer: CVPixelBuffer, fullScreenPixelBufferIsFrontCamera: Bool) -> CVPixelBuffer? {
        guard let outputPixelBufferPool = outputPixelBufferPool else { return nil }

        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool, &newPixelBuffer)

        let outputPixelBuffer = newPixelBuffer
        let outputTexture = makeTextureFromCVPixelBuffer(pixelBuffer: outputPixelBuffer)

        guard let fullScreenTexture = makeTextureFromCVPixelBuffer(pixelBuffer: fullScreenPixelBuffer) else { return nil}
        guard let pipTexture = makeTextureFromCVPixelBuffer(pixelBuffer: pipPixelBuffer) else { return nil}

        let pipPosition = SIMD2(Float(pipFrame.origin.x) * Float(fullScreenTexture.width), Float(pipFrame.origin.y) * Float(fullScreenTexture.height))
        let pipSize = SIMD2(Float(pipFrame.size.width) * Float(pipTexture.width), Float(pipFrame.size.height) * Float(pipTexture.height))
        var parameters = MixerParameters(pipPosition: pipPosition, pipSize: pipSize)

        guard let commandQueue = commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
            let computePipelineState = computePipelineState else {
                print("BothSidesMixer_computePipelineState")

                if let textureCache = textureCache {
                    CVMetalTextureCacheFlush(textureCache, 0)
                }

                return nil
        }

        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(fullScreenTexture, index: 0)
        commandEncoder.setTexture(pipTexture, index: 1)
        commandEncoder.setTexture(outputTexture, index: 2)
        commandEncoder.setBytes(UnsafeMutableRawPointer(&parameters), length: MemoryLayout<MixerParameters>.size, index: 0)

        let width = computePipelineState.threadExecutionWidth
        let height = computePipelineState.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        let threadgroupsPerGrid = MTLSize(width: (fullScreenTexture.width + width - 1) / width,
                                          height: (fullScreenTexture.height + height - 1) / height,
                                          depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)

        commandEncoder.endEncoding()
        commandBuffer.commit()

        return outputPixelBuffer
    }

    private func makeTextureFromCVPixelBuffer(pixelBuffer: CVPixelBuffer?) -> MTLTexture? {
        guard let textureCache = textureCache, let pixelBuffer = pixelBuffer  else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTextureOut: CVMetalTexture?

        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)

        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("PiPVideoMixer_cvTexture")
            CVMetalTextureCacheFlush(textureCache, 0)
            return nil
        }
        return texture
    }

    private func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) -> (
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?,
        outputFormatDescription: CMFormatDescription?) {
 
            let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
            guard inputMediaSubType == kCVPixelFormatType_32BGRA else {
                assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
                return (nil, nil, nil)
            }

            let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
            var pixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
                kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
                kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]

            var cgColorSpace: CGColorSpace? = CGColorSpaceCreateDeviceRGB()

            let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary?

            inputFormatDescriptionExtension.map { input in
                guard let colorPrimaries = input[kCVImageBufferColorPrimariesKey] else {
                    print("PiPVideoMixer_colorPrimaries")
                    return
                }

                var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]
                colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = input[kCVImageBufferYCbCrMatrixKey]
                colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = input[kCVImageBufferTransferFunctionKey]
                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties

                if let cvColorspace = input[kCVImageBufferCGColorSpaceKey], CFGetTypeID(cvColorspace) == CGColorSpace.typeID {
                    cgColorSpace = (cvColorspace as! CGColorSpace)
                } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                    cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)
                }
            }

            let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
            var cvPixelBufferPool: CVPixelBufferPool?
            CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)

            guard let pixelBufferPool = cvPixelBufferPool else {
                assertionFailure("Allocation failure: Could not allocate pixel buffer pool.")
                return (nil, nil, nil)
            }

            preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)

            var pixelBuffer: CVPixelBuffer?
            var outputFormatDescription: CMFormatDescription?
            let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
            CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)

            guard let pixel = pixelBuffer else {
                print("PiPVideoMixer_pixelBuffer")
                return (nil, nil, nil)
            }

            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixel,
                                                         formatDescriptionOut: &outputFormatDescription)
            
            pixelBuffer = nil

            return (pixelBufferPool, cgColorSpace, outputFormatDescription)
    }

    private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffer     : CVPixelBuffer?
        var pixelBuffers    = [CVPixelBuffer?]()
        var error           : CVReturn = kCVReturnSuccess
        let auxAttributes   = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
            [pixelBuffer].compactMap{ pixel in
                pixelBuffer = pixel
                pixelBuffers.append(pixelBuffer)
            }.first
            pixelBuffer = nil
        }
        pixelBuffers.removeAll()
    }
}
