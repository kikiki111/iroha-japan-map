# AGENTS.md — Iroha 基本規約

## プロジェクト
日本47都道府県旅行記録アプリ「Iroha（いろは）」

## 技術スタック
- Swift 6.0 / SwiftUI / SwiftData / iOS 17+
- 地図: GeoJSON + SwiftUI Canvas（MapKit は使わない）
- アーキテクチャ: MVVM + @Observable

## ファイル構成
Iroha/Models/ — @Model クラス
Iroha/ViewModels/ — @Observable クラス
Iroha/Views/ — SwiftUI View
Iroha/Utilities/ — パーサー・投影関数・カラー定義
Iroha/Resources/ — GeoJSON・アセット

## 禁止事項
- force unwrap（!）→ guard let / if let を使う
- MapKit の使用
- サードパーティライブラリの追加
- マジックナンバー → 定数化すること

## 詳細規約
- iOS 開発の鉄則 → /swiftui-ios スキルを参照
- GeoJSON 描画パターン → /geojson-map スキルを参照
