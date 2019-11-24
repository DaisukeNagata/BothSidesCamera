//
//  ViewController.swift
//  BothSidesCamera
//
//  Created by daisukenagata on 11/22/2019.
//  Copyright (c) 2019 daisukenagata. All rights reserved.
//

import UIKit
import AVFoundation
import BothSidesCamera

class ViewController: UIViewController {

    private var previewView: BothSidesView?
    
    @IBOutlet weak var segmentBtn: UISegmentedControl!

    lazy var  btn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: ""), for: .normal)
        btn.frame = CGRect(x: UIScreen.main.bounds.width/2 - 25, y: -25, width: 50, height: 50)
        btn.layer.cornerRadius = btn.frame.height/2
        btn.backgroundColor = .red
        return btn
    }()
    
    lazy var  btn2: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: ""), for: .normal)
        btn.frame = CGRect(x: UIScreen.main.bounds.width - 50, y: 25, width: 25, height: 25)
        btn.layer.cornerRadius = btn.frame.height/2
        btn.backgroundColor = .black
        btn.setTitle("F", for: .normal)
        btn.tintColor = .white
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        UIApplication.shared.isIdleTimerDisabled = true

        // front is builtInWideAngleCamera and builtInTrueDepthCamera only
        previewView = BothSidesView(frame: view.frame, backDeviceType: .builtInUltraWideCamera, frontDeviceType: .builtInWideAngleCamera)
        view.addSubview(previewView!)

        btn.addTarget(self, action: #selector(btaction), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(btn)
        
        btn2.addTarget(self, action: #selector(pushFlash), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(btn2)
       
        NotificationCenter.default.addObserver( self,
                                                selector:#selector(background),
                                                name: UIApplication.didEnterBackgroundNotification,object: nil)
        NotificationCenter.default.addObserver( self, selector: #selector(foreground),
                                                name: UIApplication.willEnterForegroundNotification,object: nil)
        
        view.bringSubviewToFront(segmentBtn)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // PreviewView Size
        guard let pre = previewView else { return }
        pre.frontCameraVideoPreviewView.transform = pre.frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
        pre.preViewSizeSet()
    }

    @objc func background() {
        print("background")
        flg = false
        tabBarController?.tabBar.backgroundColor = .gray
        // stop camera
        previewView!.stopRunning()
    }
    
    @objc func foreground() {
        print("foreground")
        // start camera
        previewView?.cameraStart(completion: saveBtn)
    }

    var flg = false
    @objc func btaction() {
        // start camera
        previewView?.cameraStart(completion: saveBtn)
        
        // Flash
        if flg == false {
            tabBarController?.tabBar.backgroundColor = .red
            flg = true
            btn.frame.origin.y = 0
        } else {
            tabBarController?.tabBar.backgroundColor = .gray
            flg = false
            btn.frame.origin.y = -25
        }
    }

    func saveBtn() { print("movie save") }

    // Flash
    @objc func pushFlash() { previewView?.pushFlash() }
    
    @IBAction func choice(_ sender: UISegmentedControl) {
        guard let pre = previewView else { return }
        if  sender.selectedSegmentIndex == 0 {
            pre.changeDviceTpe(backDeviceType: .builtInUltraWideCamera,
                             frontDeviceType:.builtInUltraWideCamera)
        } else {
            pre.changeDviceTpe(backDeviceType: .builtInWideAngleCamera,
                             frontDeviceType:.builtInWideAngleCamera)
        }
    }
}
