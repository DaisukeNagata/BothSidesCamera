//
//  ViewController.swift
//  BothSidesCamera
//
//  Created by daisukenagata on 11/22/2019.
//  Copyright (c) 2019 daisukenagata. All rights reserved.
//

import UIKit
import BothSidesCamera

class ViewController: UIViewController {

    private var previewView: BothSidesView?
    
    var btAction = UIButton ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //回転の検知
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        // 画面ロック
        UIApplication.shared.isIdleTimerDisabled = true

        previewView = BothSidesView(frame: view.frame)
        previewView?.setSessionPreset(state: .hd1920x1080)
        view.addSubview(previewView!)
        view.addSubview(btAction)

        btAction.frame.size = CGSize(width: 100, height: 100)
        btAction.frame.origin.y = 100
        btAction.backgroundColor = .red
        btAction.addTarget(self, action: #selector(aaaa), for: .touchUpInside)
        
        NotificationCenter.default.addObserver( self,
                                                selector:#selector(background),
                                                name: UIApplication.didEnterBackgroundNotification,object: nil)
        NotificationCenter.default.addObserver( self, selector: #selector(foreground),
                                                name: UIApplication.willEnterForegroundNotification,object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let pre = previewView else { return }
        pre.frontCameraVideoPreviewView.transform = pre.frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
    }

    @objc func background() {
        print("background")
        previewView!.stopRunning()
    }
    
    @objc func foreground() {
        print("foreground")
        previewView?.cmaeraStart(flg: flg, completion: saveBtn)
    }

    var flg = false
    @objc func aaaa() {
        previewView?.cmaeraStart(flg: flg, completion: saveBtn)
        if flg == false {
            flg = true
        } else {
            flg = false
        }
    }

    func saveBtn() {
        print("1111")
    }
}
