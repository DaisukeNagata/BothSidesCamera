# BothSidesCamera
<p align="center">
<img src="https://user-images.githubusercontent.com/16457165/69432096-5d430300-0d7c-11ea-9728-4f0b0d6f2375.png" width="800" height="600">
</p>

[![CI Status](https://img.shields.io/travis/daisukenagata/BothSidesCamera.svg?style=flat)](https://travis-ci.org/daisukenagata/BothSidesCamera)
[![Platform](http://img.shields.io/badge/platform-iOS-blue.svg?style=flat)](https://developer.apple.com/iphone/index.action)
[![Version](https://img.shields.io/cocoapods/v/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)

## Action

https://twitter.com/dbank0208/status/1197425202365251584?s=20


## Function

You can shoot in-camera and out-camera at the same time. Both screen ratios can be adjusted.

## code

```ruby
// Generation
import BothSidesCamera
private var previewView: BothSidesView?
previewView = BothSidesView(frame: view.frame)

// Start and stop recording
previewView?.cmaeraStart(completion: saveBtn)

// This is call
func saveBtn() { print("movie save") }

// All stop 
previewView.stopRunning()

// Resize
previewView.preViewSizeSet()

// Switch camera　Please check the in-camera as the camera type is different.
previewView.changeDviceTpe(backDeviceType: .builtInUltraWideCamera, frontDeviceType:.builtInUltraWideCamera)

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
