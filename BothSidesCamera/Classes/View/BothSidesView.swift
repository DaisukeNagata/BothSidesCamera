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

    public var backCameraVideoPreviewView  = BothSidesPreviewView()
    public var frontCameraVideoPreviewView = BothSidesPreviewView()

    var aVCaptureMultiCamViewModel: BothSidesMultiCamViewModel?

    private var gestureView                = UIView()
    private var pinchGesture               : UIPinchGestureRecognizer?
    private var swipePanGesture            : UIPanGestureRecognizer?
    private var tapPanGesture              : UITapGestureRecognizer?
    private var orientation                : UIInterfaceOrientation = .unknown


    public init(backDeviceType: AVCaptureDevice.DeviceType,
                 frontDeviceType: AVCaptureDevice.DeviceType) {
        super.init(frame: .zero)

        aVCaptureMultiCamViewModel = BothSidesMultiCamViewModel()
        guard let session = self.aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }

        self.frame = UIScreen.main.bounds

        backCameraVideoPreviewView.videoPreviewLayer.frame = self.bounds
        frontCameraVideoPreviewView.videoPreviewLayer.frame = self.bounds

        backCameraVideoPreviewView.videoPreviewLayer.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
        switch UIScreen.main.nativeBounds.height {
            case 2436:
            //iPhone Pro11 Bug?
            backCameraVideoPreviewView.frame.size.width = self.bounds.width + 4
            default: break
        }

        self.layer.addSublayer(backCameraVideoPreviewView.videoPreviewLayer)
        self.layer.addSublayer(frontCameraVideoPreviewView.videoPreviewLayer)
        
        backCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        frontCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)

        // builtInWideAngleCamera only
        aVCaptureMultiCamViewModel?.configureFrontCamera(frontCameraVideoPreviewView.videoPreviewLayer, deviceType: frontDeviceType)
        frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
        frontCameraVideoPreviewView.frame.origin.y -= UINavigationController.init().navigationBar.frame.height
        aVCaptureMultiCamViewModel?.configureMicrophone()

        aVCaptureMultiCamViewModel?.aModel?.recorderSet{ session.startRunning() }
        initSetting(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else { return }
        aModel.screenShot(call: call, orientation: orientation)
    }
    
    public func sameRatioFlg() {
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else { return }
        aModel.sameRatioFlg()
        sameBothViewSetting()
    }

    public func cameraMixStart(completion: @escaping() -> Void) {
        guard let session = self.aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }

        guard session.isRunning == true  else {
            session.startRunning()
            aVCaptureMultiCamViewModel?.aModel?.movieRecorder?.isRunning = false
            return
        }

        guard aVCaptureMultiCamViewModel?.aModel?.movieRecorder?.isRunning == true  else {
            aVCaptureMultiCamViewModel?.aModel?.recorderSet{ self.aVCaptureMultiCamViewModel?.aModel?.recordAction(completion: completion) }
            return
        }
        
        self.aVCaptureMultiCamViewModel?.aModel?.recordAction(completion: completion)
    }

    public func preViewSizeSet(orientation : UIInterfaceOrientation) -> Void {
        self.orientation = orientation
        oriantation { return }
        return
    }

    public func changeDviceType(backDeviceType : AVCaptureDevice.DeviceType,
                             frontDeviceType: AVCaptureDevice.DeviceType) {

        aVCaptureMultiCamViewModel?.changeDviceType()
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else { return }
        updateNormalizedPiPFrame(aModel.sameRatio )
        aVCaptureMultiCamViewModel?.configureBackCamera(backCameraVideoPreviewView.videoPreviewLayer, deviceType: backDeviceType)
    }

    //TODO: orientation.isPortrait only
    private func sameBothViewSetting() {
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        if let recognizers = gestureView.gestureRecognizers {
            for recognizer in recognizers { gestureView.removeGestureRecognizer(recognizer)
            }
        }
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else { return }
        frontCameraVideoPreviewView.frame = self.frame
        backCameraVideoPreviewView.frame = self.frame
        if orientation.isPortrait {
            if aModel.sameRatio == true {
                frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
                backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
                if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                    frontCameraVideoPreviewView.frame.origin.y = 0
                    backCameraVideoPreviewView.frame.origin.y = self.frame.height/2
                } else {
                    frontCameraVideoPreviewView.frame.origin.y = self.frame.height/2
                    backCameraVideoPreviewView.frame.origin.y = 0
                }
                updateNormalizedPiPFrame(true)
            } else {
                tapped()
            }
        } else {
            if aModel.sameRatio == true {
                let window = UIApplication.shared.windows[0]
                let safeFrame = window.safeAreaLayoutGuide.layoutFrame
                let safeAreaHlfeight = (window.frame.maxY - safeFrame.maxY)/2
                if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                    frontCameraVideoPreviewView.frame.origin.x = UIScreen.main.bounds.height - self.frame.height + safeAreaHlfeight
                    frontCameraVideoPreviewView.frame.size.height = self.frame.width/2
                    frontCameraVideoPreviewView.frame.size.width = self.frame.height/2 + UINavigationController.init().navigationBar.frame.height
                    backCameraVideoPreviewView.frame.origin.x = UIScreen.main.bounds.height - self.frame.height + safeAreaHlfeight
                    backCameraVideoPreviewView.frame.origin.y = self.frame.width/2
                    backCameraVideoPreviewView.frame.size.height = self.frame.width/2
                    backCameraVideoPreviewView.frame.size.width = self.frame.height/2 + UINavigationController.init().navigationBar.frame.height
                } else {
                    backCameraVideoPreviewView.frame.origin.x = UIScreen.main.bounds.height - self.frame.height + safeAreaHlfeight
                    backCameraVideoPreviewView.frame.size.height =  self.frame.width/2
                    backCameraVideoPreviewView.frame.size.width = self.frame.height/2 + UINavigationController.init().navigationBar.frame.height
                    frontCameraVideoPreviewView.frame.origin.x = UIScreen.main.bounds.height - self.frame.height + safeAreaHlfeight
                    frontCameraVideoPreviewView.frame.origin.y = self.frame.width/2
                    frontCameraVideoPreviewView.frame.size.height = self.frame.width/2
                    frontCameraVideoPreviewView.frame.size.width = self.frame.height/2 + UINavigationController.init().navigationBar.frame.height
                }
                updateNormalizedPiPFrame(true)
            } else {
                tapped()
            }
        }
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
    }

    // TODO Screen ratio question
    private func oriantation(_ bind: ()->()) {
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        guard let aModel = aVCaptureMultiCamViewModel?.aModel else { return }
        if aModel.sameRatio == true {
            if transform == CGAffineTransform(rotationAngle: CGFloat.pi/180 * -0.01) {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi/180*90)
            } else {
                transform = CGAffineTransform(rotationAngle: CGFloat.pi/180 * -0.01)
            }
        } else {
            if orientation.isPortrait {
                self.frame = UIScreen.main.bounds
                transform = CGAffineTransform(rotationAngle: CGFloat.pi/180 * -0.01)
            } else {
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/180*90)
            }
        }
        self.frame = UIScreen.main.bounds
        if aModel.sameRatio == false {
            switch UIScreen.main.nativeBounds.height {
            case 2436:
                switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
                case .front:
                    //iPhone Pro11 Bug?
                    self.backCameraVideoPreviewView.videoPreviewLayer.frame.size.width += 4
                case .back:
                    //iPhone Pro11 Bug?
                    self.frontCameraVideoPreviewView.videoPreviewLayer.frame.size.width += 4
                default: break
                }
            default: break
            }
        }
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
        if aModel.sameRatio == true {
            updateNormalizedPiPFrame(true)
        } else {
            updateNormalizedPiPFrame(false)
        }
        bind()
    }

    private func initSetting(_ view: UIView? = nil) {
        if let recognizers = gestureView.gestureRecognizers {
            for recognizer in recognizers { gestureView.removeGestureRecognizer(recognizer)
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

        UIView.animate(withDuration: 0.5) {
            switch self.aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                self.frontCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            case .back:
                self.backCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            default: break
            }
            self.updateNormalizedPiPFrame(false)
        }
    }

    @objc private func panTapped(sender: UIPanGestureRecognizer) {
           let position: CGPoint = sender.location(in: self)
           switch sender.state {
           case .changed:
               if orientation.isPortrait {
                   if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                       frontCameraVideoPreviewView.frame.origin.x = position.x - frontCameraVideoPreviewView.frame.width/2
                       frontCameraVideoPreviewView.frame.origin.y = position.y - frontCameraVideoPreviewView.frame.height/2
                   } else {
                       backCameraVideoPreviewView.frame.origin.x = position.x - backCameraVideoPreviewView.frame.width/2
                       backCameraVideoPreviewView.frame.origin.y = position.y - backCameraVideoPreviewView.frame.height/2
                   }
                   self.updateNormalizedPiPFrame(false)
               } else {
                   if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                       frontCameraVideoPreviewView.frame.origin.x = position.x - frontCameraVideoPreviewView.frame.width/2
                       frontCameraVideoPreviewView.frame.origin.y = position.y - frontCameraVideoPreviewView.frame.height/2
                   } else {
                       backCameraVideoPreviewView.frame.origin.x = position.x - backCameraVideoPreviewView.frame.width/2
                       backCameraVideoPreviewView.frame.origin.y = position.y - backCameraVideoPreviewView.frame.height/2
                   }
                   self.updateNormalizedPiPFrame(false)
               }
           default: break
           }
       }

    @objc private func tapped() {
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        if orientation.isPortrait {
            switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                frontCameraVideoPreviewView.transform = .identity
                frontCameraVideoPreviewView.frame = backCameraVideoPreviewView.frame
                backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
                self.bringSubviewToFront(backCameraVideoPreviewView)
                initSetting(backCameraVideoPreviewView)
            case .back:
                backCameraVideoPreviewView.transform = .identity
                backCameraVideoPreviewView.frame = frontCameraVideoPreviewView.frame
                frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
                self.bringSubviewToFront(frontCameraVideoPreviewView)
                initSetting(frontCameraVideoPreviewView)
            default: break
            }
        } else {
            switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                frontCameraVideoPreviewView.transform = .identity
                frontCameraVideoPreviewView.frame = CGRect(x: 0,
                                                           y: -UINavigationController.init().navigationBar.frame.height,
                                                           width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
                backCameraVideoPreviewView.frame = frontCameraVideoPreviewView.frame
                backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
                self.bringSubviewToFront(backCameraVideoPreviewView)
                initSetting(backCameraVideoPreviewView)
            case .back:
                backCameraVideoPreviewView.transform = .identity
                backCameraVideoPreviewView.frame = CGRect(x: 0,
                                                          y: -UINavigationController.init().navigationBar.frame.height,
                                                          width: UIScreen.main.bounds.height, height: UIScreen.main.bounds.width)
                frontCameraVideoPreviewView.frame = backCameraVideoPreviewView.frame
                frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
                self.bringSubviewToFront(frontCameraVideoPreviewView)
                initSetting(frontCameraVideoPreviewView)
            default: break
            }
        }
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
        updateNormalizedPiPFrame(false)
    }
}
