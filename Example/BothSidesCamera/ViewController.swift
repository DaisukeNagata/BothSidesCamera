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


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let alertController = UIAlertController(title: NSLocalizedString("Camera Option", comment: ""), message: "", preferredStyle: .alert)
        let storyBoard = UIAlertAction(title: NSLocalizedString("StoryBoard", comment: ""), style: .default) {
            action in
            self.start()
            alertController.dismiss(animated: true, completion: nil)
        }
        let swiftUI = UIAlertAction(title: NSLocalizedString("SwiftUI", comment: ""), style: .default) {
            action in
            SceneDelegate.delegate.window?.makeKeyAndVisible()
            self.view.removeFromSuperview()
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(swiftUI)
        alertController.addAction(storyBoard)
        self.present(alertController, animated: true, completion: nil)
    }

    func start() {
        // front is builtInWideAngleCamera and builtInTrueDepthCamera only
        previewView = BothSidesView(backDeviceType: .builtInUltraWideCamera, frontDeviceType: .builtInWideAngleCamera)
        view.addSubview(previewView!)

        btn.addTarget(self, action: #selector(btaction), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(btn)

        btn2.addTarget(self, action: #selector(pushFlash), for: .touchUpInside)
        self.tabBarController?.tabBar.addSubview(btn2)

        if segmentBtn != nil {
            view.bringSubviewToFront(segmentBtn)
        }
        // PreviewView Size
        guard let pre = previewView else { return }
        pre.preViewSizeSet(orientation: UIInterfaceOrientation.portrait)
        pre.changeDviceType(backDeviceType: .builtInWideAngleCamera, frontDeviceType:.builtInWideAngleCamera)

        NotificationCenter.default.addObserver( self,
                                                selector:#selector(background),
                                                name: UIApplication.didEnterBackgroundNotification,object: nil)
        NotificationCenter.default.addObserver( self, selector: #selector(foreground),
                                                name: UIApplication.willEnterForegroundNotification,object: nil)        
    }

    @objc func background() {
        print("background")
        flg = false
        tabBarController?.tabBar.backgroundColor = .gray
        // stop camera
        previewView!.cameraStop()
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
        // Super wide angle compatible
        sender.selectedSegmentIndex == 0 ?
            pre.changeDviceType(backDeviceType: .builtInWideAngleCamera, frontDeviceType:.builtInWideAngleCamera) :
            pre.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInWideAngleCamera)
    }
}
