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
- In the beginning, the thumbnail will be displayed directly. After the trailer is loading completed, the trailer will be auto-played from the beginning, and at this moment, the thumbnail will be hidden. After the trailer completes playback, the thumbnail image will display (Show the replay panel if you provided).
- [x] Customize layout for the control panel and replay panel
- [x] Basic functions - Play / Pause / Seek / Replay
- [x] Audio on/off - Default is OFF (muted)
- [x] Fullscreen on/off
- [x] Support PiP (Picture-in-Picture)
- [x] Support FairPlay DRM

## Requirements
- iOS 10 or above
- Xcode 12 or above

## Installation
### SwiftPM

### CocoaPods
Add a pod entry to your Podfile 
`pod 'TrailerPlayer'`
### Carthage
Add TrailerPlayer to your Cartfile `github "AbeWang/TrailerPlayer"`

## How to use
```swift
let playerView = TrailerPlayerView()
let item = TrailerPlayerItem(
            url: URL(string: "..."),
            thumbnailUrl: URL(string: "..."))
playerView.playbackDelegate = self
playerView.set(item: item)
```
#### TrailerPlayerItem settings
```swift
required public init(url: URL? = nil,                // trailer url
                     thumbnailUrl: URL? = nil,       // thumbnail url
                     thumbnailImage: UIImage? = nil, // 若已有 thumbnail 圖片時，可直接提供 
                     autoPlay: Bool = true,          // 自動播放，否則自行呼叫 play()
                     autoReplay: Bool = false,       // 播放完畢後，是否自動重新播放
                     mute: Bool = true,              // 預設播放為靜音
                     isDRMContent: Bool = false)     // 是否為 DRM 內容
```
#### TrailerPlayerPlaybackDelegate
```swift
// 當 player 播放時，可透過此 callback 更新播放時間
func trailerPlayer(_ player: TrailerPlayer, didUpdatePlaybackTime time: TimeInterval)
// 當 player 狀態改變時，可透過此 callback 更新控制面板上的播放狀態
func trailerPlayer(_ player: TrailerPlayer, didChangePlaybackStatus status: TrailerPlayerPlaybackStatus)
// 當 player item 狀態變為 readyToPlay 時觸發
func trailerPlayerPlaybackReady(_ player: TrailerPlayer)
// 當 player 播放發生錯誤時觸發
func trailerPlayer(_ player: TrailerPlayer, playbackDidFailed error: TrailerPlayerPlaybackError)
```
#### [Optional] Support PiP 
```swift
playerView.enablePictureInPicture = true
```
#### [Optional] Panel settings
```swift
let controlPanel: UIView = ... // your custom control panel
playerView.addControlPanel(controlPanel)

let replayPanel: UIView = ... // your custom replay panel
playerView.addReplayPanel(replayPanel)
```
#### [Optional] Debug view
![IMG_0012](https://user-images.githubusercontent.com/1064039/142608823-8ca6df18-f804-4605-bf16-fec677696d51.jpg)
```swift
let playerView = TrailerPlayerView()
playerView.enableDebugView = true
```
#### [Optional] Support DRM
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
#### TrailerPlayerDRMDelegate
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
