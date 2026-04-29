# AGENTS.md — Iroha 基本規約

## プロジェクト
日本47都道府県旅行記録アプリ「Iroha（いろは）」

## 技術スタック
- Swift 6.0 / SwiftUI / SwiftData / iOS 17+
- 地図: Geolonia SVG + WKWebView（MapKit の地図表示は使わない。検索 API は許可）
- 写真: PhotosUI (PhotosPicker) + Documents/Photos/ にファイル保存
- 通知: UserNotifications (UNCalendarNotificationTrigger)
- アーキテクチャ: MVVM + @Observable

## ファイル構成
Iroha/Models/ — @Model クラス（Prefecture, Visit）+ enum（Region, VisitTag, VisitMood）+ struct（Trip）
Iroha/ViewModels/ — @Observable クラス（MapViewModel）
Iroha/Views/ — SwiftUI View
Iroha/Views/Components/ — 再利用可能な小コンポーネント（NurikakeNumber, SearchOverlayView, VisitMoodBadge, VisitTagBadge）
Iroha/Services/ — ビジネスロジック（TripDetector, PhotoStorageManager, MemoryNotificationManager）
Iroha/Utilities/ — ヘルパー（PrefectureColor, ShareManager）
Iroha/Resources/ — SVG・アセット

## 禁止事項
- force unwrap（!）→ guard let / if let を使う
- MapKit の地図表示（MKMapView / Map）の使用（検索 API は除く）
- サードパーティライブラリの追加
- マジックナンバー → 定数化すること

## 詳細規約
- iOS 開発の鉄則 → /swiftui-ios スキルを参照
- 地図描画パターン → /geojson-map スキルを参照
- アーキテクチャ全体像 → docs/architecture.md を参照
