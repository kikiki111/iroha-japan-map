---
mode: agent
description: 訪問回数で色の深さが変わるシステム（実装済み）
---

# PrefectureColor 実装仕様（実装済み）

## ファイル
`Utilities/PrefectureColor.swift`

## カラーマップ（visitCount → HEX）
| visitCount | HEX      | 意味       |
|-----------|---------|-----------|
| 0         | #DDDAD4 | 未訪問（グレー）|
| 1         | #C8C4F0 | 薄紫       |
| 2         | #9F97DD | 中紫       |
| 3, 4      | #7F77DD | 紫         |
| 5以上      | #534AB7 | 深紫       |

## 実装済みの構成

### Prefecture 拡張
```swift
extension Prefecture {
    func visitColor() -> Color       // SwiftUI 用
    func visitColorHex() -> String   // WebView 用
}
```

### Color 静的メソッド
```swift
static func visitColor(count:isAllVisited:) -> Color  // コンテキスト非依存で使用可
```

### ダークモード対応テーマカラー
`Color.adaptive(light:dark:)` ヘルパーにより以下のテーマ色を定義済み：
- `irohaWashi` / `irohaWashi2` / `irohaWashi3`（背景系）
- `irohaSumi` / `irohaSumi2` / `irohaSumi3`（テキスト系）
- `irohaFuji` / `irohaFujiDk` / `irohaFujiLt` / `irohaFuji5`（メイン紫系）
- `irohaCard`（カード背景）

### 全国制覇ルール
- `MapViewModel.isAllVisited(prefectures:) -> Bool` で判定
- 全47県の visitCount >= 1 の場合、全県を #534AB7 で強制表示

### 表示モード
`MapDisplayMode` enum で地図の色分けを切替：
- `.all` — 訪問回数に応じたグラデーション（デフォルト）
- `.unvisited` — 未訪問県を #C9C3F5、訪問済みを #DDDAD4 で反転表示
