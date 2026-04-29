---
name: geojson-map
description: >-
  Geolonia SVG + WKWebView で日本地図を描画する専門知識。
  地図・SVG・色更新・タップ検出・マイルストーンアニメーションに関するタスクで自動使用する。
license: MIT
---

## アーキテクチャ（SVG + WKWebView 方式）

本プロジェクトでは GeoJSON + SwiftUI Canvas ではなく、
**Geolonia SVG (`map-full.svg`) を WKWebView に埋め込む方式**を採用している。

### ファイル構成
- `Resources/map-full.svg` — Geolonia 提供の全47都道府県 SVG
- `Views/JapanMapWebView.swift` — WKWebView サブクラス + UIViewRepresentable ラッパー
- `Views/JapanMapView.swift` — SwiftUI ビュー（ラッパーを内包）

## SVG 要素の規約
```html
<path class="prefecture" data-code="13" d="..." />
```
- `.prefecture` クラスで CSS 制御
- `data-code` 属性に都道府県コード（1〜47）

## Swift → JavaScript インターフェース

### 色更新
```javascript
window.updateColors(colorMap)  // { "13": "#534AB7", "14": "#C8C4F0", ... }
```

### ハイライト（フォーカス中の県）
```javascript
window.highlightPrefecture(code)  // code: Int or null
```

### アニメーション
```javascript
window.animateFill(code, targetColor)              // 初訪問: 白フラッシュ → グロー → 塗り
window.flashPrefectures(codes, color, ms, origMap)  // 地方制覇: 一時フラッシュ
window.waveAnimation(codes, color, totalSec)        // 全国制覇: 北→南ウェーブ
```

## JavaScript → Swift インターフェース
```javascript
window.webkit.messageHandlers.mapHandler.postMessage({
    action: "prefectureTapped",
    prefectureCode: 13
})
```
- `WKScriptMessageHandler` 経由で Swift の `onTap` コールバックに到達
- `WeakScriptHandler` で retain cycle を回避

## タップ判定
SVG の各 `<path>` 要素に touchend / click イベントリスナーを設定。
ブラウザ側で hit test が自動的に行われるため、Swift 側での CGPath 判定は不要。

## 表示モード
`MapDisplayMode` enum で色分けを切替：
- `.all` — 訪問回数に応じたグラデーション
- `.unvisited` — 訪問済み=#DDDAD4、未訪問=#C9C3F5（反転表示）
