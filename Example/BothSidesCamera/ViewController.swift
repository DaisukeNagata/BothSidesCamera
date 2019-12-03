//
//  ViewController.swift
//  BothSidesCamera_Example
//
//  Created by 永田大祐 on 2019/11/30.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import SwiftUI
import AVFoundation
import BothSidesCamera

class ViewController: UIViewController {

    private var margin: CGFloat = 50
    private var previewView: BothSidesView?

    @IBOutlet weak var segmentBtn: UISegmentedControl!

    lazy var  screenBtn: UIButton = {
        let screenBtn = UIButton()
        screenBtn.setImage(UIImage(named: ""), for: .normal)
        screenBtn.frame = CGRect(x: margin/2, y: 0, width: margin, height: margin)
        screenBtn.layer.cornerRadius = screenBtn.frame.height/2
        screenBtn.backgroundColor = .white
        return screenBtn
    }()

    lazy var  cameraBt: UIButton = {
        let cameraBt = UIButton()
        cameraBt.setImage(UIImage(named: ""), for: .normal)
        cameraBt.frame = CGRect(x: UIScreen.main.bounds.width/2 - margin/2, y: 0, width: margin, height: margin)
        cameraBt.layer.cornerRadius = cameraBt.frame.height/2
        cameraBt.backgroundColor = .red
        return cameraBt
    }()

    lazy var  flashBt: UIButton = {
        let flashBt = UIButton()
        flashBt.setImage(UIImage(named: ""), for: .normal)
        flashBt.frame = CGRect(x: UIScreen.main.bounds.width - (margin+margin/2), y: 0, width: margin, height: margin)
        flashBt.layer.cornerRadius = flashBt.frame.height/2
        flashBt.backgroundColor = .yellow
        flashBt.setTitle("F", for: .normal)
        flashBt.tintColor = .white
        return flashBt
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let alertController = UIAlertController(title: NSLocalizedString("Camera Option", comment: ""), message: "", preferredStyle: .alert)
        
        let swiftUI = UIAlertAction(title: NSLocalizedString("SwiftUI", comment: ""), style: .default) {
            action in
            SceneDelegate.delegate.contentView = ContentView()
            SceneDelegate.delegate.window?.rootViewController = UIHostingController(rootView: SceneDelegate.delegate.contentView.environmentObject(SceneDelegate.delegate.model))
            SceneDelegate.delegate.window?.makeKeyAndVisible()
            self.view.removeFromSuperview()
            alertController.dismiss(animated: true, completion: nil)
        }
        
        let storyBoard = UIAlertAction(title: NSLocalizedString("StoryBoard", comment: ""), style: .default) {
            action in
            self.start()
            alertController.dismiss(animated: true, completion: nil)
    
        }
        alertController.addAction(swiftUI)
        alertController.addAction(storyBoard)
        self.present(alertController, animated: true, completion: nil)
    }

    func start() {
        // front is builtInWideAngleCamera and builtInTrueDepthCamera only
        previewView = BothSidesView(backDeviceType: .builtInUltraWideCamera, frontDeviceType: .builtInWideAngleCamera)

        cameraBt.addTarget(self, action: #selector(btaction), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(cameraBt)

        flashBt.addTarget(self, action: #selector(pushFlash), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(flashBt)
        
        screenBtn.addTarget(self, action: #selector(screenBt), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(screenBtn)

        if segmentBtn != nil { view.bringSubviewToFront(segmentBtn) }

        // PreviewView Size
        guard let pre = previewView else { return }
        pre.changeDviceType(backDeviceType: .builtInWideAngleCamera, frontDeviceType:.builtInWideAngleCamera)
        pre.preViewSizeSet(orientation: UIInterfaceOrientation.portrait)
        view.addSubview(pre)

        NotificationCenter.default.addObserver( self,
                                                selector:#selector(background),
                                                name: UIApplication.didEnterBackgroundNotification,object: nil)
        NotificationCenter.default.addObserver( self, selector: #selector(foreground),
                                                name: UIApplication.willEnterForegroundNotification,object: nil)        
    }

    // ScreenShot
    @objc func screenBt() {
        guard let pre = previewView else { return }
        pre.screenShot(call: self.saveBtn)
    }

    @objc func background() {
        print("background")
        flg = false
        tabBarController?.tabBar.backgroundColor = .gray
        // stop camera
        previewView?.cameraStop()
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
            cameraBt.frame.origin.y = -margin/2
        } else {
            tabBarController?.tabBar.backgroundColor = .gray
            flg = false
            cameraBt.frame.origin.y = 0
        }
    }

    func saveBtn() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: NSLocalizedString("Save Screen", comment: ""), message: "", preferredStyle: .alert)
            let storyBoard = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default) {
                action in
                alertController.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(storyBoard)
            self.present(alertController, animated: true, completion: nil)
        }
        print("movie save")
    }

    // Flash
    @objc func pushFlash() { previewView?.pushFlash() }

    @IBAction func choice(_ sender: UISegmentedControl) {
        guard let pre = previewView else { return }
        // Super wide angle compatible
        sender.selectedSegmentIndex == 0 ?
            pre.changeDviceType(backDeviceType: .builtInWideAngleCamera, frontDeviceType:.builtInWideAngleCamera) :
            pre.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInWideAngleCamera)
    }
}
