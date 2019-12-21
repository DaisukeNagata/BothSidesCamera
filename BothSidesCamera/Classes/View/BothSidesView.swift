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

    public var preViewRect                 = CGRect()
    public var backCameraVideoPreviewView  : BothSidesPreviewView?
    public var frontCameraVideoPreviewView : BothSidesPreviewView?

    var aVCaptureMultiCamViewModel         : BothSidesMultiCamViewModel?

    private var gestureView                : UIView?
    private var swipePanGesture            : UIPanGestureRecognizer?
    private var tapPanGesture              : UITapGestureRecognizer?
    private var pinchGesture               : UIPinchGestureRecognizer?
    private var orientation                : UIInterfaceOrientation = .unknown


    public init(backDeviceType: AVCaptureDevice.DeviceType,
                 frontDeviceType: AVCaptureDevice.DeviceType) {
        super.init(frame: .zero)

        backCameraVideoPreviewView = BothSidesPreviewView()
        frontCameraVideoPreviewView = BothSidesPreviewView()

        aVCaptureMultiCamViewModel = BothSidesMultiCamViewModel()
        guard let aModel = aVCaptureMultiCamViewModel?.aModel,
            let session = self.aVCaptureMultiCamViewModel?.session,
            let backCameraVideoPreviewView = backCameraVideoPreviewView,
            let frontCameraVideoPreviewView = frontCameraVideoPreviewView else {
            print("AVCaptureMultiCamViewModel_init")
            return
        }

        self.frame = UIScreen.main.bounds

        backCameraVideoPreviewView.videoPreviewLayer.frame = self.bounds
        frontCameraVideoPreviewView.videoPreviewLayer.frame = self.bounds

        self.layer.addSublayer(backCameraVideoPreviewView.videoPreviewLayer)
        self.layer.addSublayer(frontCameraVideoPreviewView.videoPreviewLayer)
        
        backCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        frontCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)

        // builtInWideAngleCamera only
        aVCaptureMultiCamViewModel?.configureFrontCamera(frontCameraVideoPreviewView.videoPreviewLayer, deviceType: frontDeviceType)
        aVCaptureMultiCamViewModel?.configureMicrophone()
        aModel.recorderSet{ session.startRunning() }
        recognizerstSet(self)

        // oriantation bind
        oriantationLogic(aModel: aModel,
                         bPreviewView: backCameraVideoPreviewView,
                         fPreviewView: frontCameraVideoPreviewView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func deviceAspect(_ rect: CGRect? = nil) {
        preViewRect = rect ?? CGRect()
        switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
        case .front:
            aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
        case .back:
            aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
        default: break
        }
        tapped(true)
    }

    public func pushFlash() { aVCaptureMultiCamViewModel?.pushFlash() }

    public func cameraStop() {
        guard let session = aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }
        session.stopRunning()
    }

    public func screenShot(call: @escaping() -> Void) {
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else {
            print("AVCaptureMultiCamViewModel_screenShot")
            return
        }
        aModel.screenShot(call: call, orientation: orientation)
    }

    public func sameRatioFlg() {
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else {
            print("AVCaptureMultiCamViewModel_sameRatioFlg")
            return
        }
        aModel.sameRatioModel.sameRatio = aModel.sameRatioModel.sameRatio == false ? true : false
        aModel.sameRatioFlg()
        sameBothViewSetting()
    }

    public func cameraMixStart(completion: @escaping() -> Void) {
            guard let model = aVCaptureMultiCamViewModel?.aModel, let session = aVCaptureMultiCamViewModel?.session else {
                print("AVCaptureMultiCamViewModel_cameraMixStart")
                return
            }
            guard session.isRunning == true  else {
                session.startRunning()
                model.vm.valueSet(model.bothObservarModel)
                print("AVCaptureMultiCamViewModel_cameraMixStart_isRunning")
                return
            }
            
            guard model.bothObservarModel.isRunning == true  else {
                aVCaptureMultiCamViewModel?.aModel?.recorderSet{ self.aVCaptureMultiCamViewModel?.aModel?.recordAction(completion: completion) }
                model.bothObservarModel.isRunning = true
                model.vm.valueSet(model.bothObservarModel)
                print("AVCaptureMultiCamViewModel_cameraMixStart_isRunning")
                return
            }
            model.bothObservarModel.isRunning = false
            model.vm.valueSet(model.bothObservarModel)
            self.aVCaptureMultiCamViewModel?.aModel?.recordAction(completion: completion)
    }

    public func preViewSizeSet(orientation : UIInterfaceOrientation) -> Void {
        self.orientation = orientation
        oriantation {
            print("AVCaptureMultiCamViewModel_preViewSizeSet")
            return
        }
        return
    }

    public func changeDviceType(backDeviceType : AVCaptureDevice.DeviceType,
                                frontDeviceType: AVCaptureDevice.DeviceType) {

        aVCaptureMultiCamViewModel?.changeDviceType()
        guard let aModel = aVCaptureMultiCamViewModel?.aModel,
            let backCameraVideoPreviewView = backCameraVideoPreviewView else {
                print("AVCaptureMultiCamViewModel_changeDviceType")
                return
        }
        updateNormalizedPiPFrame(aModel.sameRatioModel.sameRatio)
        aVCaptureMultiCamViewModel?.configureBackCamera(backCameraVideoPreviewView.videoPreviewLayer, deviceType: backDeviceType)
    }

    private func sameBothViewSetting() {
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)

        if let recognizers = gestureView?.gestureRecognizers {
            for recognizer in recognizers { gestureView?.removeGestureRecognizer(recognizer)
            }
        }

        guard let aModel = aVCaptureMultiCamViewModel?.aModel,
            let backCameraVideoPreviewView = backCameraVideoPreviewView,
            let frontCameraVideoPreviewView = frontCameraVideoPreviewView else {
                print("AVCaptureMultiCamViewModel_frontCameraVideoPreviewView")
                return
        }
        
        let bView: BothSidesPreviewView
        let fView: BothSidesPreviewView

        if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
            bView = backCameraVideoPreviewView
            fView = frontCameraVideoPreviewView
        } else {
            bView = frontCameraVideoPreviewView
            fView = backCameraVideoPreviewView
        }

        if aModel.sameRatioModel.sameRatio == true {
            bView.transform = .identity
            bView.frame = preViewRect
            fView.transform = .identity
            fView.frame = preViewRect
            bView.transform = bView.transform.scaledBy(x: 0.5, y: 0.5)
            fView.transform = fView.transform.scaledBy(x: 0.5, y: 0.5)

            if UIInterfaceOrientation.landscapeRight == orientation  {
                bView.frame.origin.x = self.frame.width/2 - bView.frame.width*2 + bView.videoViewAreaWidth()/2
                fView.frame.origin.x = self.frame.width/2 - fView.frame.width*2 + fView.videoViewAreaWidth()/2
                bView.frame.origin.y = preViewRect.height/2
                fView.frame.origin.y = 0
            } else {
                bView.frame.origin.y = bView.frame.height
                fView.frame.origin.y = 0
            }
            updateNormalizedPiPFrame(true)
        } else {
            tapped(false)
        }

        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
    }

    private func oriantation(_ bind: ()->()) {
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)

        guard let aModel = aVCaptureMultiCamViewModel?.aModel else {
                print("AVCaptureMultiCamViewModel_frontCameraVideoPreviewView")
                return
        }

        if aModel.sameRatioModel.sameRatio == true { sameBothViewSetting() }
        switch orientation {
        case.landscapeRight:
            aModel.orientationModel.interfaceOrientation = false
        case.landscapeLeft:
            aModel.orientationModel.interfaceOrientation = nil
        default:
            aModel.orientationModel.interfaceOrientation = true
        }
    
        aModel.vm.orientationValueSet(aModel.orientationModel)

        updateNormalizedPiPFrame(aModel.sameRatioModel.sameRatio)
        aVCaptureMultiCamViewModel?.aModel?.transFormCheck = self.transform
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
        bind()
    }

    private func oriantationLogic(aModel: BothSidesMultiCamSessionModel, bPreviewView: BothSidesPreviewView, fPreviewView: BothSidesPreviewView) {

        aModel.vm.observe(for: aModel.vm.orientationModel ?? BothObservable()) { _ in 
            let bView: BothSidesPreviewView
            let fView: BothSidesPreviewView
            
            if self.aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                bView = bPreviewView
                fView = fPreviewView
            } else {
                bView = fPreviewView
                fView = bPreviewView
            }
    
            switch self.orientation {
            case.landscapeRight:
                if aModel.sameRatioModel.sameRatio == false {
                    bView.frame.origin.x = -UINavigationController.init().navigationBar.frame.height - bView.videoViewAreaWidth()
                    fView.frame.origin.x = self.preViewRect.width - (fView.frame.width + UINavigationController.init().navigationBar.frame.height + fView.videoViewAreaWidth())
                }
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/180 * 90).scaledBy(x: -1, y: -1)
            default:
                if aModel.sameRatioModel.sameRatio == false {
                    bView.frame.origin.x = 0
                    fView.frame.origin.x = 0
                }
                self.transform = self.orientation.isPortrait == true ?
                    CGAffineTransform(rotationAngle: CGFloat.pi/180 * -0.01) :
                    CGAffineTransform(rotationAngle: CGFloat.pi/180 * 90)
                break
            }
        }
    }

    private func recognizerstSet(_ view: UIView? = nil) {
        if let recognizers = gestureView?.gestureRecognizers {
            for recognizer in recognizers { gestureView?.removeGestureRecognizer(recognizer)
            }
        }
        swipePanGesture = UIPanGestureRecognizer(target: self, action:#selector(panTapped))
        view?.addGestureRecognizer(swipePanGesture ?? UIPanGestureRecognizer())

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchSwipGesture))
        view?.addGestureRecognizer(pinchGesture ?? UIPinchGestureRecognizer())

        tapPanGesture = UITapGestureRecognizer(target: self, action:#selector(tapped))
        tapPanGesture?.numberOfTapsRequired = 1
        view?.addGestureRecognizer(tapPanGesture ?? UITapGestureRecognizer())
        gestureView = view ?? UIView()
    }

    private func updateNormalizedPiPFrame(_ flg: Bool? = nil) {

        let fullScreenVideoPreviewView: BothSidesPreviewView
        let pipVideoPreviewView: BothSidesPreviewView

        guard let backCameraVideoPreviewView = backCameraVideoPreviewView,
            let frontCameraVideoPreviewView = frontCameraVideoPreviewView else {
                print("AVCaptureMultiCamViewModel_updateNormalizedPiPFrame")
                return
        }

        if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .back {
            fullScreenVideoPreviewView = frontCameraVideoPreviewView
            pipVideoPreviewView = backCameraVideoPreviewView
        } else if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
            fullScreenVideoPreviewView = backCameraVideoPreviewView
            pipVideoPreviewView = frontCameraVideoPreviewView
        } else {
            fatalError("Unexpected pip device position: \(String(describing: aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition))")
        }

        if flg == false {
            let pipFrameInFullScreenVideoPreview = pipVideoPreviewView.convert(pipVideoPreviewView.bounds, to: fullScreenVideoPreviewView)
            let normalizedTransform = CGAffineTransform(scaleX: 1.0 / fullScreenVideoPreviewView.frame.width, y: 1.0 / fullScreenVideoPreviewView.frame.height)
            aVCaptureMultiCamViewModel?.aModel?.normalizedPipFrame = pipFrameInFullScreenVideoPreview.applying(normalizedTransform)
        } else {
            aVCaptureMultiCamViewModel?.aModel?.normalizedPipFrame = CGRect(x: 0.25, y: 0, width: 0.5, height: 0.5)
        }
    }

    @objc private func pinchSwipGesture(_ sender: UIPinchGestureRecognizer) {

        guard let backCameraVideoPreviewView = backCameraVideoPreviewView,
            let frontCameraVideoPreviewView = frontCameraVideoPreviewView else {
                print("AVCaptureMultiCamViewModel_pinchSwipGesture")
                return
        }

        UIView.animate(withDuration: 0.5) {
            switch self.aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                    frontCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            case .back:
                    backCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            default: break
            }
            self.updateNormalizedPiPFrame(false)
        }
    }

    @objc private func panTapped(sender: UIPanGestureRecognizer) {
        let position: CGPoint = sender.location(in: self)
        guard let backCameraVideoPreviewView = backCameraVideoPreviewView,
            let frontCameraVideoPreviewView = frontCameraVideoPreviewView else {
                print("AVCaptureMultiCamViewModel_panTapped")
                return
        }
        switch sender.state {
        case .ended:
            self.updateNormalizedPiPFrame(false)
        case .changed:
            if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                frontCameraVideoPreviewView.frame.origin.x = position.x - frontCameraVideoPreviewView.frame.width/2
                frontCameraVideoPreviewView.frame.origin.y = position.y - frontCameraVideoPreviewView.frame.height/2
            } else {
                backCameraVideoPreviewView.frame.origin.x = position.x - backCameraVideoPreviewView.frame.width/2
                backCameraVideoPreviewView.frame.origin.y = position.y - backCameraVideoPreviewView.frame.height/2
            }
        default: break
        }
    }

    @objc private func tapped(_ flg: Bool) {
        guard let backCameraVideoPreviewView = backCameraVideoPreviewView,
            let frontCameraVideoPreviewView = frontCameraVideoPreviewView else {
                print("AVCaptureMultiCamViewModel_tapped")
                return
        }
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        backCameraVideoPreviewView.transform = .identity
        backCameraVideoPreviewView.frame = preViewRect
        frontCameraVideoPreviewView.transform = .identity
        frontCameraVideoPreviewView.frame = preViewRect
        switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
        case .front:
            backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
            backCameraVideoPreviewView.frame.origin = CGPoint(x: 0, y: 0)
            aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
            self.bringSubviewToFront(backCameraVideoPreviewView)
            flg == false ? recognizerstSet(backCameraVideoPreviewView):nil
        case .back:
            frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
            frontCameraVideoPreviewView.frame.origin = CGPoint(x: 0, y: 0)
            aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
            self.bringSubviewToFront(frontCameraVideoPreviewView)
            flg == false ? recognizerstSet(frontCameraVideoPreviewView):nil
        default: break
        }
        if UIInterfaceOrientation.landscapeRight == orientation  {
            let window = UIApplication.shared.windows[0]
            let safeFrame = window.safeAreaLayoutGuide.layoutFrame
            let safeAreaHeight = (window.frame.maxY - safeFrame.maxY)
            switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                backCameraVideoPreviewView.frame.origin.x = -UINavigationController.init().navigationBar.frame.height - safeAreaHeight
                frontCameraVideoPreviewView.frame.origin.x = backCameraVideoPreviewView.frame.width/2
            case .back:
                frontCameraVideoPreviewView.frame.origin.x = -UINavigationController.init().navigationBar.frame.height - safeAreaHeight
                backCameraVideoPreviewView.frame.origin.x = frontCameraVideoPreviewView.frame.width/2
            default: break
            }
        }
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
        updateNormalizedPiPFrame(false)
    }
}
