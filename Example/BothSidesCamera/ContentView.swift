//
//  ContentView.swift
//  ddddddd
//
//  Created by 永田大祐 on 2019/11/26.
//  Copyright © 2019 永田大祐. All rights reserved.
//

import SwiftUI
import AVFoundation
import BothSidesCamera

struct ContentView: View {

    @State private var enableLogging = false
    @State private var selectorIndex = 0
    @State private var margin: CGFloat = 0
    @State private var bView =  bothSidesView()

    @ObservedObject private var observer = notificationObserver()

    var body: some View {
        VStack {
            bView

                .frame(minWidth: margin, maxWidth: .infinity, minHeight: margin, maxHeight: .infinity)

            Picker("Numbers", selection: $selectorIndex) {
                ForEach(0 ..< self.bView.numbers.count) { index in
                    Text( self.bView.numbers[index]).tag(index)
                }
            }.pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Button(
                    action: {
                        if self.selectorIndex > 1 {
                            if  self.bView.numbers[2] == self.bView.st {
                                self.bView.numbers[2] = "Start"
                                self.bView.cameraStart()
                            } else {
                                self.bView.numbers[2] = "Stop"
                                self.bView.cameraStart()
                            }
                        } else {
                            self.bView.changeDviceType(self.bView.bothSidesView,numbers: self.selectorIndex)
                        }
                },
                    label: {
                        Image(systemName: .init())
                            .padding(100)
                            .frame(width: 50, height: 50)
                            .imageScale(.large)
                            .background(Color.red)
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
    @State var st = "Stop"
    @State var numbers = ["Wide","Usually","Stop"]
    @State var bothSidesView = BothSidesView(frame: UIScreen.main.bounds, backDeviceType: .builtInUltraWideCamera, frontDeviceType: .builtInWideAngleCamera)
    func makeUIView(context: UIViewRepresentableContext<bothSidesView>) -> BothSidesView {
        bothSidesView.frontCameraVideoPreviewView.transform = bothSidesView.frontCameraVideoPreviewView.transform.scaledBy(x: 0.5, y: 0.5)
        return  bothSidesView
    }
    func updateUIView(_ bView: BothSidesView, context: Context) {
        bothSidesView = bView
        bView.preViewSizeSet()
    }
    
    func changeDviceType(_ bView: BothSidesView, numbers: Int) {
        if numbers == 0 {
            print(bView)
            bView.changeDviceType(backDeviceType: .builtInTelephotoCamera, frontDeviceType:.builtInWideAngleCamera)
        } else {
            bView.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInWideAngleCamera)
        }
    }
    
    func flash() { bothSidesView.pushFlash() }

    func cameraStart() { bothSidesView.cameraStart(completion: saveBtn) }
    
    func saveBtn() { print("movie save") }
}

final class notificationObserver: ObservableObject {
    private var notificationCenter: NotificationCenter
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver( self, selector: #selector(foreground), name: UIApplication.willEnterForegroundNotification,object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    @objc func foreground(notification: Notification) {
        print("foreground")
        let b = bothSidesView()
        b.numbers = ["Wide","Usually","Stop"]
    }
}
