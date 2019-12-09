# BothSidesCamera
<p align="center">
<img src="https://user-images.githubusercontent.com/16457165/69432096-5d430300-0d7c-11ea-9728-4f0b0d6f2375.png" width="800" height="600">
</p>

[![CI Status](https://img.shields.io/travis/daisukenagata/BothSidesCamera.svg?style=flat)](https://travis-ci.org/daisukenagata/BothSidesCamera)
[![Platform](http://img.shields.io/badge/platform-iOS-blue.svg?style=flat)](https://developer.apple.com/iphone/index.action)
[![Version](https://img.shields.io/cocoapods/v/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)

## Requirements
- iPhoneX, Xs, XR, XsMax, Pro
- iOS 13.2+
- Xcode 11.2.1

## Version 0.8.9 ~ The preview screen and playback screen are perfectly matched

## Version 0.8 ~ Preview screen with the same ratio and recording function 

```ruby
Purple button logic 　Horizontal support
```

<p align="center">
<img src=https://user-images.githubusercontent.com/16457165/70378328-5f06ec00-1962-11ea-80a1-537d74855814.gif>
</p>



## Version 0.7 ~ Preview screen with the same ratio and recording function 
<p align="center">
<img src=https://user-images.githubusercontent.com/16457165/70306631-b5810700-184a-11ea-88e6-69ced997ddde.gif>
</p>

## Version 0.6 ~　Equipped with screenshot function. You can shoot images with the left button, even during video recording, when not recording.

```ruby
Gray button screenshot

White Button is a record button

Blue Button switches camera

Yellow Button is lighting.

```
<p align="center">
<img src=https://user-images.githubusercontent.com/16457165/70024317-13a8b280-15dd-11ea-925c-6e84e2aff3d8.jpeg width="350" height="700">
</p>

## Function

You can shoot in-camera and out-camera at the same time. Both screen ratios can be adjusted.
While using, use about 260MB of memory with iPhonePro. Memory usage is about 80MB with the stop method.

## code

####  Horizontal rotation movement

```ruby
class SceneDelegate
func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        model.orientation = windowScene.interfaceOrientation
        contentView.bView.orientation(model: model)     
}

struct ContentView 
@EnvironmentObject var model: OrientationModel

final class OrientationModel
@Published var orientation: UIInterfaceOrientation = .unknown

```
<br>

```ruby
// Generation
import BothSidesCamera
@ObservedObject private var observer = KeyboardResponder()

// Start and stop recording
previewView?.cameraStart(completion: saveBtn)

// This is call
func saveBtn() { print("movie save") }

// All stop 
previewView.cameraStop()

// Resize
previewView.preViewSizeSet()

// Switch camera　Please check the in-camera as the camera type is different.
previewView.changeDviceType(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInUltraWideCamera)

//　Method to match the preview screen and playback screen
previewView.deviceAspect(rect: bView.backCameraVideoPreviewView.frame)

```

## How to

```ruby
pinchGesture　→Scale

2 continuous taps →Preview screen switching 

Trace the preview screen　→Move preview screen

```


## Installation

BothSidesCamera is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BothSidesCamera'
```

## [Charthage](https://github.com/Carthage/Carthage)

Officially supported: Carthage 0.34 and up.

Add this to Cartfile
```ruby
github "daisukenagata/BothSidesCamera"
```

Terminal command
```bash
$ carthage update --platform iOS
```

## Author

daisukenagata, dbank0208@gmail.com

## License

BothSidesCamera is available under the MIT license. See the LICENSE file for more info.
