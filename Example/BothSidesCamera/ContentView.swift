//
//  ContentView.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/26.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import SwiftUI
import BothSidesCamera

struct ContentView: View {

    @State var frameSize     : CGFloat = 25
    @State var selectorIndex = 0
    @State var didTap: Bool  = false
    @State var bView         = SidesView()

    @EnvironmentObject var model: OrientationModel

    var body: some View {
        VStack {
            bView.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)

            HStack {
                Button(
                    action: {
                        self.bView.cameraLogic(.gray)
                },
                    label: {
                        Text("").modifier(MyModifier(color: .gray, frameSize: frameSize))
                })
                    .alert(isPresented: $model.showingAlert) { Alert(title: Text("Save Screen")) }

                Button(
                    action: {
                        self.didTap = self.didTap ? false : true
                        self.bView.cameraLogic(.white)
                },
                    label: {
                        Text("").background(didTap ? Color.red : Color.white).modifier(MyModifier(color: .white, frameSize: frameSize))
                })

                Button(
                    action: {
                        self.bView.cameraLogic(.blue)
                },
                    label: {
                        Text("").modifier(MyModifier(color: .blue, frameSize: frameSize))
                })

                Button(
                    action: {
                        self.bView.cameraLogic(.purple)
                },
                    label: {
                          Text("").modifier(MyModifier(color: .purple, frameSize: frameSize))
                })

                Button(
                    action: {
                        self.bView.cameraLogic(.yellow)
                },
                    label: {
                        Text("").modifier(MyModifier(color: .yellow, frameSize: frameSize))
                })

            }.onAppear {
                self.model.contentView = self
                self.bView.orientationModel = self.model
                _ = self.bView.changeDviceType(self.bView.bothSidesView,numbers: self.selectorIndex)

                // preview origin set example
                guard let backCameraVideoPreviewView = self.bView.bothSidesView.backCameraVideoPreviewView else { return }
                backCameraVideoPreviewView.videoPreviewLayer.frame = CGRect(x: 0,
                                                                            y: 0,
                                                                            width : backCameraVideoPreviewView.frame.width,
                                                                            height: backCameraVideoPreviewView.frame.width * 1.77777777777778)
                self.bView.bothSidesView.deviceAspect(backCameraVideoPreviewView.frame)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SidesView: UIViewRepresentable {

    var index = 0
    var orientationModel: OrientationModel?
    @State var bothSidesView = BothSidesView(backDeviceType: .builtInUltraWideCamera,
                                             frontDeviceType: .builtInWideAngleCamera)

    func saveBtn() {
        DispatchQueue.main.async {
            self.orientationModel?.showingAlert = true
        }
    }

    // Super wide angle compatible
    func changeDviceType(_ bView: BothSidesView, numbers: Int) -> ContentView? {
        numbers == 0 ?
            bView.changeDviceType(backDeviceType: .builtInWideAngleCamera, frontDeviceType:.builtInWideAngleCamera) :
            bView.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInWideAngleCamera)
        return nil
    }

    // Modifying state during view update, this will cause undefined behavior.  bothSidesView = bView
    func updateUIView(_ bView: BothSidesView, context: Context) {
        DispatchQueue.main.async { self.bothSidesView = bView }
    }
    
    mutating func cameraLogic(_ color: Color) {
        switch color {
        case .gray: self.screenShot()
        case .white: self.cameraStart()
        case .blue: index = index == 0 ? 1 : 0; _ = self.changeDviceType(self.bothSidesView, numbers: index)
        case .purple: self.sameRatioFlg()
        case.yellow: self.flash()
        default: break
        }
    }

    func flash() { bothSidesView.pushFlash() }

    func cameraStop() { bothSidesView.cameraStop()}
    
    func sameRatioFlg() {bothSidesView.sameRatioFlg()}
    
    func screenShot() { bothSidesView.screenShot(call: saveBtn)}

    func cameraStart() { bothSidesView.cameraMixStart(completion: saveBtn) }

    func makeUIView(context: UIViewRepresentableContext<SidesView>) -> BothSidesView { return  bothSidesView }

    func orientation(model: OrientationModel) { bothSidesView.preViewSizeSet(orientation:  model.orientation) }

}

final class OrientationModel: ObservableObject {

    @Published var showingAlert = false
    @Published var orientation: UIInterfaceOrientation = .unknown

    var contentView: ContentView?

    private var notificationCenter: NotificationCenter

    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver( self, selector: #selector(foreGround), name: UIApplication.willEnterForegroundNotification,object: nil)
        notificationCenter.addObserver( self, selector: #selector(backGround), name: UIApplication.didEnterBackgroundNotification,object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func foreGround(notification: Notification) {
        guard let contentView = contentView else { return }
        contentView.bView.cameraStart()
    }

    @objc func backGround(notification: Notification) {
        guard let contentView = contentView else { return }
        contentView.didTap = false
        contentView.bView.cameraStop()
    }
}

struct MyModifier: ViewModifier {

    var color         : Color? = nil
    var frameSize     : CGFloat? = nil
    var verticalSet   : Edge.Set? = nil
    var horizontalSet : Edge.Set? = nil
    var verticalSize  : CGFloat? = nil
    var horizontalSize: CGFloat? = nil
    
    @State private var margin: CGFloat = 10

    func body(content: Content) -> some View {
        return content
            .padding(frameSize ?? 0.0)
            .background(color)
            .padding(verticalSet ?? Edge.Set.init(rawValue: 0), verticalSize ?? 0.0)
            .padding(horizontalSet ?? Edge.Set.init(rawValue: 0), horizontalSize ?? 0.0)
            .clipShape(Circle())
            .padding(.leading, margin)
            .padding(.trailing, margin)
    }
}
