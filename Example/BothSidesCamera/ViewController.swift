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
    lazy var  btn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: ""), for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.layer.cornerRadius = 15
        btn.backgroundColor = .red
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        UIApplication.shared.isIdleTimerDisabled = true

        previewView = BothSidesView(frame: view.frame)
        previewView?.setSessionPreset(state: .hd1920x1080)
        view.addSubview(previewView!)
        view.addSubview(btn)
        btn.addTarget(self, action: #selector(btaction), for: .touchUpInside)
        
        self.tabBarController?.tabBar.addSubview(btn)
        self.tabBarController?.tabBar.centerXAnchor.constraint(equalTo: btn.centerXAnchor).isActive = true
        self.tabBarController?.tabBar.topAnchor.constraint(equalTo: btn.centerYAnchor).isActive = true

        NotificationCenter.default.addObserver( self,
                                                selector:#selector(background),
                                                name: UIApplication.didEnterBackgroundNotification,object: nil)
        NotificationCenter.default.addObserver( self, selector: #selector(foreground),
                                                name: UIApplication.willEnterForegroundNotification,object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // PreviewView Size
        guard let pre = previewView else { return }
        pre.frontCameraVideoPreviewView.transform = pre.frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
    }

    @objc func background() {
        print("background")
        // stop camera
        previewView!.stopRunning()
    }
    
    @objc func foreground() {
        print("foreground")
        // start camera
        previewView?.cmaeraStart(completion: saveBtn)
    }

    var flg = false
    @objc func btaction() {
        // start camera
        previewView?.cmaeraStart(completion: saveBtn)
        if flg == false {
            self.tabBarController?.tabBar.backgroundColor = .red
            flg = true
        } else {
            self.tabBarController?.tabBar.backgroundColor = .gray
            flg = false
        }
    }

    func saveBtn() {
        print("movie save")
    }
}
