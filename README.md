# SBrick-iOS
[![Version](https://img.shields.io/cocoapods/v/SBrick-iOS.svg?style=flat)](http://cocoapods.org/pods/SBrick-iOS)
[![License](https://img.shields.io/cocoapods/l/SBrick-iOS.svg?style=flat)](http://cocoapods.org/pods/SBrick-iOS)
[![Platform](https://img.shields.io/cocoapods/p/SBrick-iOS.svg?style=flat)](http://cocoapods.org/pods/SBrick-iOS)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

SWift 3, iOS 10+

## Installation

SBrick-iOS is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SBrick-iOS"
```

## Usage

```swift
var manager = SBrickManager(delegate: self)
manager.startDiscovery()


func sbrickManager(_ sbrickManager: SBrickManager, didDiscover sbrick: SBrick) {
    //connect
    sbrick.delegate = self
    sbrickManager.connect(to: sbrick)
}

func sbrickReady(_ sbrick: SBrick) {
    //send a command
    sbrick.send(command: .drive(channelId: 0, cw: true, power: 0xFF))
}
```

## Author

Barak Harel

## License

SBrick-iOS is available under the MIT license. See the LICENSE file for more info.
