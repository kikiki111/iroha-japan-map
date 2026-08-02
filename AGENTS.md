# AGENTS.md — Iroha 基本規約

## プロジェクト
日本47都道府県旅行記録アプリ「Iroha（いろは）」

## 技術スタック
- Swift 6.0 / SwiftUI / SwiftData / iOS 18+
- 地図: Geolonia SVG + WKWebView（MapKit の地図表示は使わない。検索 API は許可）
- 写真: PhotosUI (PhotosPicker) + VisitPhoto モデルで SwiftData / CloudKit 同期
  （旧 Documents/Photos/ ファイルは PhotoMigration で順次転記、Phase A は併存）
- 永続化: SwiftData (Visit, VisitPhoto) + 静的 struct (Prefecture)
- クラウド同期: CloudKit Private DB (Phase 6 で有効化予定)
- アーキテクチャ: MVVM + @Observable

## ファイル構成
Iroha/Models/ — @Model クラス（Visit, VisitPhoto, TravelStyleRecord）+ static struct（Prefecture）+ enum（Region, VisitKind, TravelStylePreset, TravelStylePalette, TravelStyleIcon, VisitMood, VisitTransport, Badge/BadgeCategory/TravelerTier）+ struct（Trip, TravelStyle）
Iroha/ViewModels/ — @Observable クラス（MapViewModel）
Iroha/Views/ — SwiftUI View（CloudSyncOnboardingView 含む）
Iroha/Views/Components/ — 再利用可能な小コンポーネント（NurikakeNumber, VisitMoodBadge, VisitTagBadge, VisitTransportBadge, VisitCompanionBadge, VisitResidenceBadge, BadgeCollectionView, BadgeStampView, LocationSearchCompleter, SakuraEffectView, SettingsComponents）
Iroha/Services/ — ビジネスロジック（TripDetector, PhotoStorageManager, VisitPhotoStore, VisitPrefectureMigration, PhotoMigration, CloudSyncStatusObserver, CompanionSuggestionStore, TravelStyleStore）
Iroha/Utilities/ — ヘルパー（PrefectureColor, VisitStats, ShareManager, DistanceCalculator, TravelStyleCatalog）
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
