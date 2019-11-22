//
//  BothSidesView.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//
import UIKit
import AVFoundation

public class BothSidesView: UIView, UIGestureRecognizerDelegate {

    var aVCaptureMultiCamViewModel: BothSidesMultiCamViewModel?

    private var backCameraVideoPreviewView  = BothSidesPreviewView()
    private var frontCameraVideoPreviewView = BothSidesPreviewView()

    private var tapFlg                     = false
    private let margin                     : CGFloat = 30
    private let animationTimer             : Double = 3.0
    private var pinchGesture               : UIPinchGestureRecognizer?
    private var swipePanGesture            : UIPanGestureRecognizer?
    private var tapPanGesture              : UITapGestureRecognizer?
    private var doubleTapGestureRecognizer : UITapGestureRecognizer?


    public override init(frame: CGRect) {
        super.init(frame: .zero)

        aVCaptureMultiCamViewModel = BothSidesMultiCamViewModel()
        guard let session = self.aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }

        self.frame = UIScreen.main.bounds
        backCameraVideoPreviewView.frame = self.frame
        frontCameraVideoPreviewView.frame = self.frame
        frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)

        self.layer.addSublayer(backCameraVideoPreviewView.videoPreviewLayer)
        self.layer.addSublayer(frontCameraVideoPreviewView.videoPreviewLayer)

        backCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        frontCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)

        updateNormalizedPiPFrame()

        aVCaptureMultiCamViewModel?.configureBackCamera(backCameraVideoPreviewView.videoPreviewLayer)
        aVCaptureMultiCamViewModel?.configureFrontCamera(frontCameraVideoPreviewView.videoPreviewLayer)
        aVCaptureMultiCamViewModel?.configureMicrophone()
        session.startRunning()
        initSetting(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func cmaeraStart(flg: Bool, completion: @escaping() -> Void) {
        aVCaptureMultiCamViewModel?.aModel?.recordAction(flg: flg, completion: completion)
    }

    private func initSetting(_ view: UIView? = nil) {

        swipePanGesture = UIPanGestureRecognizer(target: self, action:#selector(panTapped))
        view?.addGestureRecognizer(swipePanGesture ?? UIPanGestureRecognizer())

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchSwipGesture))
        view?.addGestureRecognizer(pinchGesture ?? UIPinchGestureRecognizer())

        tapPanGesture = UITapGestureRecognizer(target: self, action:#selector(tapped))
        tapPanGesture?.numberOfTapsRequired = 1
        view?.addGestureRecognizer(tapPanGesture ?? UITapGestureRecognizer())
    }

    private func updateNormalizedPiPFrame() {
        let fullScreenVideoPreviewView: BothSidesPreviewView
        let pipVideoPreviewView: BothSidesPreviewView

        if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .back {
            fullScreenVideoPreviewView = frontCameraVideoPreviewView
            pipVideoPreviewView = backCameraVideoPreviewView
        } else if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
            fullScreenVideoPreviewView = backCameraVideoPreviewView
            pipVideoPreviewView = frontCameraVideoPreviewView
        } else {
            fatalError("Unexpected pip device position: \(String(describing: aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition))")
        }

        let pipFrameInFullScreenVideoPreview = pipVideoPreviewView.convert(pipVideoPreviewView.bounds, to: fullScreenVideoPreviewView)
        let normalizedTransform = CGAffineTransform(scaleX: 1.0 / fullScreenVideoPreviewView.frame.width, y: 1.0 / fullScreenVideoPreviewView.frame.height)

        aVCaptureMultiCamViewModel?.aModel?.normalizedPipFrame = pipFrameInFullScreenVideoPreview.applying(normalizedTransform)
    }

    @objc private func pinchSwipGesture(_ sender: UIPinchGestureRecognizer) {
        if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
            frontCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
        } else {
            backCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
        }
        if sender.state == .ended { updateNormalizedPiPFrame() }
    }

    @objc private func panTapped(sender: UIPanGestureRecognizer) {
        let position: CGPoint = sender.location(in: self)
        switch sender.state {
        case .ended:
             updateNormalizedPiPFrame()
            break
        case .possible:
            break
        case .began:
            break
        case .changed:
            if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                frontCameraVideoPreviewView.frame.origin.x = position.x - frontCameraVideoPreviewView.frame.width
                frontCameraVideoPreviewView.frame.origin.y = position.y - frontCameraVideoPreviewView.frame.height/2
            } else {
                backCameraVideoPreviewView.frame.origin.x = position.x - backCameraVideoPreviewView.frame.width
                backCameraVideoPreviewView.frame.origin.y = position.y - backCameraVideoPreviewView.frame.height/2
            }
            break
        case .cancelled:
            break
        case .failed:
            break
        @unknown default:
            fatalError()
        }
    }

    @objc private func tapped(sender: UIPanGestureRecognizer) {
        tapPanGesture = nil
        pinchGesture = nil
        doubleTapGestureRecognizer = nil
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
            frontCameraVideoPreviewView.transform = .identity
            frontCameraVideoPreviewView.frame = self.frame
            backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
            aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
            self.bringSubviewToFront(backCameraVideoPreviewView)
            initSetting(backCameraVideoPreviewView)
        } else {
            backCameraVideoPreviewView.transform = .identity
            backCameraVideoPreviewView.frame = self.frame
            frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
            aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
            self.bringSubviewToFront(frontCameraVideoPreviewView)
            initSetting(frontCameraVideoPreviewView)
        }
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
        updateNormalizedPiPFrame()
    }
}
