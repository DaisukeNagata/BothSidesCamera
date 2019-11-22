//
//  BothSidesUtil.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/21.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }

    func angleOffsetFromPortraitOrientation(at position: AVCaptureDevice.Position) -> Double {
        switch self {
        case .portrait:
            return position == .front ? .pi : 0
        case .portraitUpsideDown:
            return position == .front ? 0 : .pi
        case .landscapeRight:
            return -.pi / 2.0
        case .landscapeLeft:
            return .pi / 2.0
        default:
            return 0
        }
    }
    
}

extension AVCaptureConnection {
    func videoOrientationTransform(relativeTo destinationVideoOrientation: AVCaptureVideoOrientation) -> CGAffineTransform {
        let videoDevice: AVCaptureDevice
        if let deviceInput = inputPorts.first?.input as? AVCaptureDeviceInput, deviceInput.device.hasMediaType(.video) {
            videoDevice = deviceInput.device
        } else {
            return .identity
        }

        let fromAngleOffset = videoOrientation.angleOffsetFromPortraitOrientation(at: videoDevice.position)
        let toAngleOffset = destinationVideoOrientation.angleOffsetFromPortraitOrientation(at: videoDevice.position)
        let angleOffset = CGFloat(toAngleOffset - fromAngleOffset)
        let transform = CGAffineTransform(rotationAngle: angleOffset)

        return transform
    }
}

extension Bundle {

    var applicationName: String {
        if let name = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return name
        } else if let name = object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }

        return "-"
    }
}
