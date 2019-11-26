//
//  ContentView.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/26.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import SwiftUI
import AVFoundation
import BothSidesCamera

struct ContentView: View {

    @State var didTap:Bool = false
    @State private var selectorIndex = 0
    @State private var margin: CGFloat = 0
    @State var numbers = ["Wide","Usually"]
    @State private var bView =  bothSidesView()
    @ObservedObject private var observer = notificationObserver()

    var body: some View {
        VStack {
            bView
                .frame(minWidth: margin, maxWidth: .infinity, minHeight: margin, maxHeight: .infinity)
            Picker("Numbers", selection: $selectorIndex) {
                ForEach(0 ..< self.numbers.count) { index in
                    Text( self.numbers[index]).tag(index)
                }
            }.pickerStyle(SegmentedPickerStyle())
            self.bView.changeDviceType(self.bView.bothSidesView,numbers: self.selectorIndex)

            HStack {
                Button(
                    action: {
                       self.didTap = self.didTap ? false : true
                       self.bView.cameraStart()
                },
                    label: {
                        Image(systemName: .init())
                            .padding(100)
                            .frame(width: 50, height: 50)
                            .imageScale(.large)
                            .background(didTap ? Color.red : Color.white)
                            .clipShape(Circle())
                }
                ).padding(.top, 10)

                Button(
                    action: {
                        self.bView.flash()
                },
                    label: {
                        Image(systemName: .init())
                            .frame(width: 50, height: 50)
                            .imageScale(.large)
                            .background(Color.white)
                            .clipShape(Circle())
                }
                ) .padding(.leading, 100).padding(.top, 10)
            }.onAppear {
                self.observer.contentView = self
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct bothSidesView: UIViewRepresentable {
    @State var bothSidesView = BothSidesView(frame: UIScreen.main.bounds, backDeviceType: .builtInUltraWideCamera, frontDeviceType: .builtInWideAngleCamera)
    func makeUIView(context: UIViewRepresentableContext<bothSidesView>) -> BothSidesView {
        bothSidesView.frontCameraVideoPreviewView.transform = bothSidesView.frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
        return  bothSidesView
    }
    func updateUIView(_ bView: BothSidesView, context: Context) {
        bothSidesView = bView
        bView.preViewSizeSet()
    }
    
    func changeDviceType(_ bView: BothSidesView, numbers: Int) -> ContentView? {
        if numbers == 0 {
            bView.changeDviceType(backDeviceType: .builtInTelephotoCamera, frontDeviceType:.builtInWideAngleCamera)
        } else {
            bView.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInWideAngleCamera)
        }
        return nil
    }
    
    func flash() { bothSidesView.pushFlash() }

    func cameraStart() { bothSidesView.cameraStart(completion: saveBtn) }
    
    func cameraStop() { bothSidesView.cameraStop() }
    
    func saveBtn() { print("movie save") }
}

final class notificationObserver: ObservableObject {
    
    var contentView: ContentView?
    private var notificationCenter: NotificationCenter
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver( self, selector: #selector(backGround), name: UIApplication.didEnterBackgroundNotification,object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc func backGround(notification: Notification) {
        guard let contentView = contentView else { return }
        contentView.didTap = false
    }
}
