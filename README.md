# Trailer Player
iOS video player for trailer.

https://user-images.githubusercontent.com/1064039/135829008-7afd2ce1-c4b5-4138-8976-c010df067e19.mov

## spec v1.0.0
- [x] 沒有 trailer 的 content，單純顯示 thumbnail。
- [x] 有 trailer 的 content，可以自動播放 trailer，且在播放途中可以隨時暫停播放。
- [x] Preview 功能不會有倍速播放，但是 progress bar 必須要有，且用戶可以自由調整 progress bar 觀看在不同秒數的內容。
- [x] Preview 功能不允許用 AirPlay 投到輸出設備上。
- [x] Preview 功能的聲音部份，預設是 off，但用戶可以點選音量按鈕，以打開聲音。
- [x] 對於同時有 thumbnail 與 trailer 的 content，會先顯示 thumbnail，此時背景會持續 loading trailer。直到 trailer loading 完成、ready to play 的時候，即顯示 trailer 並自動播放，此時縮圖會被隱藏起來。
- [x] Preview 功能可以全螢幕播放。
- [x] Trailer 的顯示 size 會跟 thumbnail 完全一致。
- [x] 當 trailer 播放完畢之後，播放畫面會停止，且正中間會有一個 Replay 按鈕，用戶可以選點此按鈕以重播此 trailer。
- [x] 可以提供 trailer 的倒數秒數，並會隨著播放而逐漸減少秒數。
- [x] 不可背景播放。
- [x] 從背景回到前景時，要繼續播放。
- [x] 當影片 Buffering 的時候要秀 loading。
- [x] trailer 顯示時，要隱藏 thumbnail image。
- [x] 不可在 Remote Control Center 裡顯示資訊。
- [x] Preview 播完後回到 thumbnail。
- [x] 如果用戶的網路，從連網 => 斷網 => 再連網的時候，trailer 會接續播放。
- [ ] Refactor code
- [ ] Support iOS 10~15
- [x] Support SPM
- [x] Profile: leaks, allocations, time profiler

## How to use
#### 建立 TrailerPlayerView
```swift
let playerView = TrailerPlayerView()
let item = TrailerPlayerItem(
            url: URL(string: "..."),
            thumbnailUrl: URL(string: "..."))
playerView.delegate = self
playerView.set(item: item)
```
#### TrailerPlayerItem 細節設定
```swift
required public init(url: URL? = nil,          // 預告片 url
                     thumbnailUrl: URL? = nil, // 縮圖 url
                     autoPlay: Bool = true,    // 自動播放，否則自行呼叫 play()
                     autoReplay: Bool = false, // 播放完畢後，是否自動重新播放
                     mute: Bool = true)        // 預設播放為靜音
```
#### TrailerPlayerViewDelegate
```swift
// 如果 autoReplay 為 false 時，播放完畢會觸發
func trailerPlayerViewDidEndPlaying(_ view: TrailerPlayerView)
// 當 player 播放時，可透過此 callback 更新播放時間
func trailerPlayerView(_ view: TrailerPlayerView, didUpdatePlaybackTime time: TimeInterval)
```
#### PIP 支援
```
預計 v1.1.0 提供
```
#### DRM 支援
```
預計 v1.2.0 提供
```
#### 其它細節操作可參考 Sample code
