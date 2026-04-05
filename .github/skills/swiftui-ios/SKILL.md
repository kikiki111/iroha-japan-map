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

// ❌ 間違い（直接インスタンス化しない）
let context = ModelContext(container)
```

### View の分割
- body は 80 行以内。超えたら別 View に切り出す

### アンチパターン
- @Query を ViewModel に書く（View に書く）
- バックグラウンドスレッドで UI を更新する
