# Trailer Player

<p align="left">
<a href="https://cocoapods.org/pods/TrailerPlayer"><img src="https://img.shields.io/cocoapods/v/TrailerPlayer.svg?style=flat"></a>
<a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat"></a>
</p>

iOS video player for trailer. You can customize layout for the control panel.
Support PiP and DRM. 

https://user-images.githubusercontent.com/1064039/136514197-452bfecd-fe68-465d-9621-781056485286.mov

Icons by Icons8 (https://icons8.com)

## Features
- [x] For the content without trailers :
- Show thumbnail directly
- [x] For the content with trailers :
- In the beginning, the thumbnail will be displayed directly. After the trailer is loading completed, the trailer will be auto-played from the beginning, and at this moment, the thumbnail will be hidden. After the trailer completes playback, the thumbnail image will display (Or show the replay panel if you provided it).
- [x] Customize layout for the control panel and replay panel
- [x] Basic functions - Play / Pause / Stop / Seek / Replay
- [x] Audio on/off - Default is OFF (muted)
- [x] Fullscreen on/off
- [x] Support PiP (Picture-in-Picture)
- [x] Support FairPlay DRM
- [x] Debug view - Bitrate / Framerate / Resolution / TrailerUrl / PlaybackItemUrl 

## Requirements
- iOS 10 or above
- Xcode 12 or above

## Installation
### Swift Package Manager
Add a package dependency to your Xcode project, select File > Swift Packages > Add Package Dependency and enter repository URL `https://github.com/AbeWang/TrailerPlayer`.
Then import `import TrailerPlayer`.

### CocoaPods
Add a pod entry to your Podfile :
```ruby
target 'YourApp' do
    pod 'TrailerPlayer', '~> 1.4.8'
    ...
```
Install pods
```
$ pod install
```
And then import `import TrailerPlayer`.

### Carthage
Add TrailerPlayer to your Cartfile : 
```
github "AbeWang/TrailerPlayer" ~> 1.4.8
```
Run `carthage update`
```
$ carthage update --use-xcframeworks
```
Add the TrailerPlayer xcframework to your project. (XCFramework will not require the usage of the carthage copy-frameworks script anymore.)

## How to use
```swift
let playerView = TrailerPlayerView()
let item = TrailerPlayerItem(
            url: URL(string: "..."),
            thumbnailUrl: URL(string: "..."))
playerView.playbackDelegate = self
playerView.set(item: item)
```
### TrailerPlayerItem settings
```swift
required public init(url: URL? = nil,                
                     thumbnailUrl: URL? = nil,       
                     thumbnailImage: UIImage? = nil, 
                     autoPlay: Bool = true,          
                     autoReplay: Bool = false,       
                     mute: Bool = true,              
                     isDRMContent: Bool = false)     
```
### TrailerPlayerPlaybackDelegate
```swift
func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval)
func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus)
func trailerPlayerPlaybackReady(_ player: TrailerPlayer)
func trailerPlayer(_ player: TrailerPlayer, playbackDidFailed error: TrailerPlayerPlaybackError)
```
### [Optional] Manual Play 
```swift
let item = TrailerPlayerItem(
            url: URL(string: "..."),
            thumbnailUrl: URL(string: "..."),
            autoPlay: false)
playerView.set(item: item)
playerView.manualPlayButton = ... // your custom button
```
### [Optional] Support PiP 
```swift
playerView.enablePictureInPicture = true
```
### [Optional] Panel settings
```swift
let controlPanel: UIView = ... // your custom control panel
playerView.addControlPanel(controlPanel)

let replayPanel: UIView = ... // your custom replay panel
playerView.addReplayPanel(replayPanel)
```
### [Optional] Debug view
![IMG_0012](https://user-images.githubusercontent.com/1064039/142608823-8ca6df18-f804-4605-bf16-fec677696d51.jpg)
```swift
let playerView = TrailerPlayerView()
playerView.enableDebugView = true
```
### [Optional] Support DRM
```swift
let playerView = TrailerPlayerView()
let item = TrailerPlayerItem(
            url: URL(string: "..."),
            thumbnailUrl: URL(string: "..."),
            isDRMContent: true)
playerView.playbackDelegate = self
playerView.DRMDelegate = self
playerView.set(item: item)

// DRM Delegate
extension ViewController: TrailerPlayerDRMDelegate {
    
    func certUrl(for player: TrailerPlayer) -> URL {
        return URL(string: ...) // your certificate url
    }
    
    func ckcUrl(for player: TrailerPlayer) -> URL {
        return URL(string: ...) // your ckc url
    }
}
```
### TrailerPlayerDRMDelegate
```swift
// CKC(Content Key Context) URL
func ckcUrl(for player: TrailerPlayer) -> URL
// Certificate URL
func certUrl(for player: TrailerPlayer) -> URL
// Optional: content Id for SPC(Server Playback Context) message
func contentId(for player: TrailerPlayer) -> String?
// Optional: HTTP header fields for CKC request
func ckcRequestHeaderFields(for player: TrailerPlayer) -> [(headerField: String, value: String)]?
```

## Detailed Example
A more detailed example can be found here https://github.com/AbeWang/TrailerPlayer/tree/main/Example, or open `TrailerPlayer.xcodeproj`
