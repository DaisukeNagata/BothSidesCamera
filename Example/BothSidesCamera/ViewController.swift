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
        view.addSubview(previewView!)
        view.addSubview(btAction)

        btAction.frame.size = CGSize(width: 100, height: 100)
        btAction.backgroundColor = .red
        btAction.addTarget(self, action: #selector(aaaa), for: .touchUpInside)
        
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
