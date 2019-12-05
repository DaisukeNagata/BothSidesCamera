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
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
