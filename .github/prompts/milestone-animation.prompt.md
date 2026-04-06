---
mode: agent
description: マイルストーン達成時のアニメーション実装
---

# マイルストーンアニメーション — 実装仕様

## 設計方針
- ゲームっぽくしない：バッジ・通知・ポップアップは出さない
- 静かに反応する：アニメーションのみ
- 各マイルストーンは 1 回だけ（UserDefaults で管理）

## 4種類のアニメーション

### 1. 初訪問（visitCount が 0→1）
- 対象: その1県
- .easeInOut(duration: 0.4)
- `withAnimation(.easeInOut(duration: 0.4)) { prefecture.isVisited = true }`

### 2. 半分制覇（visitedCount == 25）
- 対象: 地図全体
- mapScale: 1.0 → 1.02 → 1.0（0.8秒）
- UserDefaults["milestone_25_shown"] で1回管理
- `withAnimation(.easeInOut(duration: 0.8).repeatCount(1, autoreverses: true)) { mapScale = 1.02 }`

### 3. 地方制覇（1地方の全県が埋まったとき）
- 対象: その地方の全県
- #AFA9EC に0.3秒フラッシュ → 元の色に戻る
- UserDefaults["region_\(region.rawValue)_shown"] で管理

### 4. 全国制覇（visitedCount == 47）
- UserDefaults["milestone_47_shown"] で1回だけ
- アルゴリズム:
  1. 全県を緯度順（北→南）にソート
  2. delay = Double(index) / 47.0 * 3.0 秒
  3. .easeInOut(duration: 0.3) で各県を #534AB7 に変化
- 完了後: 全県を常に #534AB7 で固定表示（isAllVisited == true）

## Prefecture モデルへの追加
- `var latitude: Double` — 都道府県の中心緯度（静的データ）

## 完了条件
- 4種類すべて動作する
- 各マイルストーンが1回だけ実行される
- 同時に複数アニメーションが走らない
- force unwrap なし
