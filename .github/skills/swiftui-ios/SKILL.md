---
name: swiftui-ios
description: >-
  SwiftUI と SwiftData を使った iOS アプリ開発の専門知識。
  Swift・SwiftUI・SwiftData・iOS・アクセシビリティに関するタスクで自動使用する。
license: MIT
---

## iOS 開発の鉄則

### 絶対に守るルール
- force unwrap（!）は使わない。guard let / if let を使う
- @State は View 内のみ。ViewModel には @Observable を使う
- すべての View に #Preview を書く
- インタラクティブな要素に .accessibilityLabel() を付ける

### SwiftData パターン
```swift
// ✅ 正しい
@Environment(\.modelContext) private var context
@Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

// ❌ 間違い（直接インスタンス化しない）
let context = ModelContext(container)
```

### 本プロジェクトで使用中の SwiftUI パターン
- `@Bindable var` — @Observable クラスの双方向バインディング
- `PhotosPicker` — 写真選択（PhotosUI）
- `.presentationDetents([.fraction(0.7), .large])` — シートの高さ制御
- `.presentationBackground()` — シート背景カスタマイズ
- `@AppStorage` — UserDefaults バインディング（テーマ設定、オンボーディング等）
- `Layout` プロトコル — カスタムフローレイアウト（FlowLayout）
- `ImageRenderer` — SwiftUI View → UIImage 変換（シェア機能）

### View の分割
- body は 80 行以内。超えたら別 View / private computed property に切り出す
- 大きい View は MARK コメントでセクション分割する

### アンチパターン
- @Query を ViewModel に書く（View に書く）
- バックグラウンドスレッドで UI を更新する
- @Observable ViewModel を @State 以外で保持する
