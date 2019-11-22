# BothSidesCamera
<p align="center">
<img src="https://user-images.githubusercontent.com/16457165/69422323-bef87280-0d66-11ea-98c3-cd397f7041e2.png" width="800" height="600">
</p>

[![CI Status](https://img.shields.io/travis/daisukenagata/BothSidesCamera.svg?style=flat)](https://travis-ci.org/daisukenagata/BothSidesCamera)
[![Version](https://img.shields.io/cocoapods/v/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)
[![License](https://img.shields.io/cocoapods/l/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)
[![Platform](https://img.shields.io/cocoapods/p/BothSidesCamera.svg?style=flat)](https://cocoapods.org/pods/BothSidesCamera)


## Function

You can shoot in-camera and out-camera at the same time. Both screen ratios can be adjusted.

## code

```
Generation
### import BothSidesCamera
private var previewView: BothSidesView?
previewView = BothSidesView(frame: view.frame)

resolution
previewView?.setSessionPreset(state: .hd1920x1080)

Start and stop recording
previewView?.cmaeraStart(flg: flg, completion: saveBtn)

this is call
func saveBtn() { print("movie save") }

all stop 
previewView.stopRunning()


```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

BothSidesCamera is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BothSidesCamera'
```

## Author

daisukenagata, dbank0208@gmail.com

## License

BothSidesCamera is available under the MIT license. See the LICENSE file for more info.
