---
mode: agent
description: マイルストーン達成時のアニメーション（実装済み）
---

# マイルストーンアニメーション — 実装仕様（実装済み）

## 設計方針
- ゲームっぽくしない：バッジ・通知・ポップアップは出さない
- 静かに反応する：アニメーション + 控えめなトースト
- 各マイルストーンは 1 回だけ（UserDefaults で管理）

## 5種類のマイルストーン（MilestoneType enum）

### 優先度順（高→低）
national > half > region > count > first

### 1. 全国制覇（nationalConquest / visitedCount == 47）
- UserDefaults["milestone_47_shown"] で1回管理
- WKWebView の `waveAnimation()` で北→南ウェーブ（3.0秒）
- 全県を緯度順（北→南）にソートし、delay = (index / 47) * 3.0秒 で順に #534AB7 に変化
- 完了後: 全県を常に #534AB7 で固定表示

### 2. 半分制覇（halfConquest / visitedCount >= 25）
- UserDefaults["milestone_25_shown"] で1回管理
- トースト表示「25県達成！半分制覇！」
- mapScale: 1.0 → 1.02 → 1.0（0.4秒×2）

### 3. 地方制覇（regionConquest / 1地方の全県が埋まったとき）
- UserDefaults["region_\(region.rawValue)_shown"] で管理
- WKWebView の `flashPrefectures()` でその地方の全県を #AFA9EC にフラッシュ（300ms）→ 元の色に戻る

### 4. N県達成（countMilestone / 5, 10, 15, 20, 30, 35, 40, 45）
- UserDefaults["milestone_\(count)_shown"] で管理（下位も同時にマーク）
- トースト表示「N県達成！」
- mapScale: 1.0 → 1.01 → 1.0（0.3秒×2）

### 5. 初訪問（firstVisit / visitCount が 0→1）
- 対象: 新規訪問した1県
- WKWebView の `animateFill()` で白フラッシュ → 塗りかけグロー → 訪問色に変化（0.8秒）
- シート閉じ後に発火（deferredFillAnimations キューで制御）

## 実装箇所
- `MapViewModel.detectMilestone()` — マイルストーン検出ロジック
- `ContentView.MapTabView.executeMilestoneAnimation()` — SwiftUI 側アニメーション実行
- `JapanMapWebViewWrapper.updateUIView()` — WebView 側アニメーション実行
- `MapViewModel.milestoneToast` — トースト表示テキスト
- `MapViewModel.mapScale` — 地図スケールアニメーション

## Prefecture モデル
- `var latitude: Double` — 都道府県の中心緯度（シードデータに含む）
