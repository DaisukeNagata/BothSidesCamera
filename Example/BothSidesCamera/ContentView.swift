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
    @State var numbers = ["Wide","Usually"]
    @EnvironmentObject var env: ViewModel

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
                       self.bView.cameraStart()
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

class ViewModel: ObservableObject {
    @Published var sel = 0 {
        didSet {
            oneSelected = oldValue == 1
        }
    }
    var oneSelected = false
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
        _ = bothSidesView()
    }
}
