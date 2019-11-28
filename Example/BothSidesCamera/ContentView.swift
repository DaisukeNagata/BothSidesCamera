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

    @State var didTap:Bool = false
    @State var bView =  SidesView()
    @State private var selectorIndex = 0
    @State private var margin: CGFloat = 100
    @State private var numbers = ["Wide","Usually"]
    @EnvironmentObject var model: OrientationModel

    var body: some View {
        VStack {
            bView
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            
            Picker("Numbers", selection: $selectorIndex) {
                ForEach(0 ..< self.numbers.count) { index in
                    Text( self.numbers[index]).tag(index)
                }
            }.pickerStyle(SegmentedPickerStyle())
            self.bView.changeDviceType(self.bView.bothSidesView,numbers: self.selectorIndex)
            self.bView.orientation(model: model)
            HStack {
                Button(
                    action: {
                       self.didTap = self.didTap ? false : true
                        self.bView.cameraStart()
                },
                    label: {
                        Image(systemName: .init())
                            .padding(margin)
                            .frame(width: margin/2, height: margin/2)
                            .imageScale(.large)
                            .background(didTap ? Color.red : Color.white)
                            .clipShape(Circle())
                }
                ).padding(.top, margin/10)

                Button(
                    action: {
                        self.bView.flash()
                },
                    label: {
                        Image(systemName: .init())
                            .frame(width: margin/2, height: margin/2)
                            .imageScale(.large)
                            .background(Color.yellow)
                            .clipShape(Circle())
                }
                ) .padding(.leading, margin).padding(.top, margin/10)
            }.onAppear {
                self.model.contentView = self
                self.model.bothSidesView = self.bView
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

    @State var bothSidesView = BothSidesView(backDeviceType: .builtInUltraWideCamera,
                                             frontDeviceType: .builtInWideAngleCamera)

    func makeUIView(context: UIViewRepresentableContext<SidesView>) -> BothSidesView {
        return  bothSidesView
    }

    func updateUIView(_ bView: BothSidesView, context: Context) {
        bothSidesView = bView
    }
    
    func changeDviceType(_ bView: BothSidesView, numbers: Int) -> ContentView? {

        numbers == 0 ?
            bView.changeDviceType(backDeviceType: .builtInTelephotoCamera, frontDeviceType:.builtInWideAngleCamera) :
            bView.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInWideAngleCamera)
        
        return nil
    }
    
    func orientation(model: OrientationModel) -> ContentView? {
        bothSidesView.preViewSizeSet(orientation:  model.orientation)
        bothSidesView.isHidden = false
        return nil
    }
    
    func flash() { bothSidesView.pushFlash() }

    func cameraStart() { bothSidesView.cameraStart(completion: saveBtn) }
    
    func cameraStop() { bothSidesView.cameraStop() }
    
    func saveBtn() { print("movie save") }
    
}

final class OrientationModel: ObservableObject {
    
    var bothSidesView: SidesView?
    var contentView: ContentView?
    private var notificationCenter: NotificationCenter
    @Published var orientation: UIInterfaceOrientation = .unknown
    
    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver( self, selector: #selector(foreGround), name: UIApplication.willEnterForegroundNotification,object: nil)
        notificationCenter.addObserver( self, selector: #selector(backGround), name: UIApplication.didEnterBackgroundNotification,object: nil)
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func foreGround(notification: Notification) {
        guard let bothSidesView = bothSidesView else { return }
        bothSidesView.cameraStart()
    }

    @objc func backGround(notification: Notification) {
        guard let contentView = contentView ,let bothSidesView = bothSidesView else { return }
        contentView.didTap = false
        bothSidesView.cameraStop()
    }
    
}
