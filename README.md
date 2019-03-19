# NYVideoKit

[![CI Status](https://img.shields.io/travis/niyaoyao/NYVideoKit.svg?style=flat)](https://travis-ci.org/niyaoyao/NYVideoKit)
[![Version](https://img.shields.io/cocoapods/v/NYVideoKit.svg?style=flat)](https://cocoapods.org/pods/NYVideoKit)
[![License](https://img.shields.io/cocoapods/l/NYVideoKit.svg?style=flat)](https://cocoapods.org/pods/NYVideoKit)
[![Platform](https://img.shields.io/cocoapods/p/NYVideoKit.svg?style=flat)](https://cocoapods.org/pods/NYVideoKit)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

### Add repo
To use NYVideoKit components, you must add this repo to your local machine.

### Pod install
Lotus is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'git@github.com:niyaoyao/NYVideoKitSpec.git'
platform :ios, '8.0' 
target 'project-target-name' do
pod 'NYVideoKit'

end
```

### Access during Runtime

**[access] This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.**

Add key-value elements below in **Info.plist** file to solve the crash.

```
<key>NSCameraUsageDescription</key>
<string>Please allow App to use Camera.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Please allow App to use Microphone.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Please allow App to use Photo Library Assests.</string>
```


## Author

niyaoyao, nycode.jn@gmail.com

## License

NYVideoKit is available under the MIT license. See the LICENSE file for more info.
