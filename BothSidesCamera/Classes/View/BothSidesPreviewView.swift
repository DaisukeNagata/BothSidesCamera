//
//  BothSidesViewPreviewView.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/20.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import UIKit
import AVFoundation

public class BothSidesPreviewView: UIView {
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        layer.videoGravity = .resizeAspectFill
        return layer
    }
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func videoViewAreaWidth() -> CGFloat {
        var safeAreaWidth: CGFloat = 0
        if UIApplication.shared.windows == [] {
            safeAreaWidth = 44
        } else {
            let window = UIApplication.shared.windows
            let safeFrame = window[0].safeAreaLayoutGuide.layoutFrame
            safeAreaWidth = (window[0].frame.maxX - safeFrame.maxX)
        }
        return safeAreaWidth
    }
}
