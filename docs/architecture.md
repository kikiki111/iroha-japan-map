# Iroha アーキテクチャ設計

## 画面構成（3タブ）
ContentView
  ├── TabView
  │   ├── MapTabView（地図タブ）
  │   │   ├── MapDisplayMode 切替バー（すべて / 未訪問）
  │   │   ├── JapanMapView → JapanMapWebViewWrapper（Geolonia SVG + WKWebView）
  │   │   ├── RegionSuggestion（地方制覇サジェスト）
  │   │   ├── IrohaStatsBar（訪問数・達成率・地方別ドット）
  │   │   └── MilestoneToast（マイルストーン達成通知）
  │   │
  │   ├── TimelineView（旅日記タブ）
  │   │   ├── MemoryCardView（◯年前の今日）
  │   │   ├── YearSwitcher（年切替）
  │   │   ├── YearHeader（年間サマリー + シェアボタン）
  │   │   └── MonthlyTripCards（月別旅行カード）
  │   │
  │   └── JourneyTrackerView（旅の軌跡タブ）
  │       ├── HeroSection（全国制覇進捗）
  │       ├── ThreeColumnStats（訪問回数・旅行回数・地方制覇）
  │       ├── RegionDotsSection（地方別ドット）
  │       ├── TravelDistanceSection（旅の距離 + 最遠地）
  │       ├── MilestoneSection（マイルストーンバッジ）
  │       └── NavigationLink → SettingsView
  │
  └── OnboardingView（初回起動時のみ）

## シート（モーダル）
  ├── PrefectureDetailSheet（県詳細 — タップで開く）
  │   ├── HeaderSection（県名・読み・地方・訪問回数）
  │   ├── PhotoGallery（写真一覧 — 横スクロール）
  │   ├── QuickRecordButton（今日の訪問を1タップ記録）
  │   ├── AddDetailButton（詳細で追加）
  │   └── VisitList（訪問履歴 — スワイプで編集・削除）
  ├── VisitInputSheet（訪問記録 / 編集 — PrefectureDetailSheet 内）
  ├── AddVisitSheetView（訪問追加 — TimelineView から）
  ├── EditVisitSheetView（訪問編集 — TimelineView から）
  └── TripDetailSheet（旅の詳細 — TimelineView から）

## データモデル

永続化層は **SwiftData (Visit + VisitPhoto)** + **静的 struct (Prefecture)** + **派生集計 (VisitStats)** の三層構造。

### Prefecture（静的 struct — SwiftData 外）
- id: Int（都道府県コード 1〜47）
- name, nameKana, region, latitude, longitude, distanceFromTokyo
- `Prefecture.all` の static let 配列で 47 件を保持
- ヘルパー: `Prefecture.by(id:)` / `Prefecture.by(name:)`
- 訪問状態 (isVisited, visitCount) は持たず、`VisitStats` で動的算出
- CloudKit 同期対象から外すことで、複数端末での seed 重複・unique 制約問題を回避

### Visit（SwiftData @Model — CloudKit 同期対象 / Phase 6 で有効化）
- prefectureName, prefectureID（Prefecture.id への参照キー）
- startDate, endDate, note
- tag: VisitTag?（日帰り / 宿泊 / 居住）
- mood: VisitMood?（楽 / 癒 / 感 / 驚 / 懐 / 静）
- transports, tripName, companions, location, locationLatitude, locationLongitude
- photos: [VisitPhoto]?（@Relationship, cascade delete, optional 必須）
- 旧 photoFilenames / photoThumbnails / photoFilename / photoThumbnail（PhotoMigration 完了確認まで併存）
- 互換ヘルパー: totalPhotoCount, sortedPhotoThumbnails, sortedPhotoFilenames, sortedPhotos

### VisitPhoto（SwiftData @Model — CloudKit 同期対象 / Phase 6 で有効化）
- id: UUID
- imageData: Data?（@Attribute(.externalStorage) — CloudKit Asset として同期）
- thumbnailData: Data?（300px、通常フィールド）
- orderIndex, createdAt
- legacyFilename: String?（旧 Documents/Photos/ ファイル名 — 移行元の重複検出キー）
- visit: Visit?（optional 必須）
- 保存時に **必ず** 最大 2048px / 5MB に強制縮小（VisitPhotoStore）

### VisitStats（派生集計 ヘルパー）
- visits 群を引数に取り、prefectureID → count の辞書を生成
- API: count(for:), isVisited(_:), isAllVisited, visitedPrefectures, visitsByRegion(), isRegionConquered(_:), color(for:), colorHex(for:), signature
- View 階層で 1 度作ってサブビューに渡す

### Trip（非永続化 — TripDetector で動的生成）
- visits: [Visit]
- computed: startDate, endDate, isSingleVisit, prefectureNames

### Region（enum）
hokkaido, tohoku, kanto, chubu, kinki, chugoku, shikoku, kyushu

### VisitTag（enum）
none, dayTrip, stay, lived

### VisitMood（enum — 伝統色ベース）
none, tanoshi(楽/桜), iyashi(癒/若草), kandou(感/藤), odoroki(驚/山吹), natsukashi(懐/茜), shizuka(静/浅葱)

## データフロー
Prefecture（SwiftData）←→ MapViewModel → JapanMapView（WKWebView）
                                ↓
                         Visit → TripDetector → TimelineView / JourneyTrackerView

## タップ処理の流れ
1. SVG 上の都道府県要素を JavaScript がタップ検出（touchend / click）
2. WKScriptMessageHandler 経由で Swift に { action, prefectureCode } を送信
3. MapViewModel.focus(prefecture:) で対象を選択
4. PrefectureDetailSheet が表示される
5. 訪問記録追加後、visitColorHex() で色を再計算し WebView に反映
6. シート閉じ後に初訪問アニメーション（animateFill）を発火

## 旅ルート自動検出アルゴリズム（TripDetector）
1. 全 Visit を startDate でソート
2. 前の Visit の effectiveEndDate から次の Visit の startDate が 3日以内 → 同じ旅行グループ
3. グループを Trip オブジェクトに変換（FNV-1a ハッシュで確定的 UUID 生成）
4. Trip を月別にグルーピングして TimelineView に表示

## マイルストーンシステム
- MapViewModel.detectMilestone() で訪問保存後に検出
- 優先度: nationalConquest > halfConquest > regionConquest > countMilestone > firstVisit
- UserDefaults でマイルストーンごとに1回管理
- アニメーション: WebView 側（SVG fill）+ SwiftUI 側（mapScale, toast）

## サービス層
- TripDetector — 旅行グループ自動検出（3日ルール）
- VisitPhotoStore — 写真の保存・取得・削除（VisitPhoto 経由、2048px/5MB に強制縮小、新旧ハイブリッドロード）
- PhotoStorageManager — 旧 Documents/Photos/ への読み書き（Phase A 移行期間中に PhotoMigration / 互換ヘルパーから利用、Phase B 完了で削除予定）
- VisitPrefectureMigration — 既存 Visit の prefectureID を prefectureName から backfill（起動時 1 回、scan ベース判定で冪等）
- PhotoMigration — 既存 Documents/Photos/ ファイルを VisitPhoto に転記（写真単位冪等、旧データは Phase B まで保持）
- CloudSyncStatusObserver — CloudKit 同期状態の集約・公開（CKAccountStatus + NWPathMonitor + UserDefaults）
- MemoryNotificationManager — 「今日の記憶」通知スケジュール（UNCalendarNotificationTrigger）
- ShareManager — 訪問マップ画像シェア（VisitStats を引数に取り、年別シェア時は filteredVisits 由来の stats を渡す）

## CloudKit 同期（Phase 6 で有効化予定）
- ModelContainer の `cloudKitDatabase: .private("iCloud.com.qumo.Iroha")` で有効化
- Schema は [Visit.self, VisitPhoto.self]（Prefecture は static struct、同期対象外）
- ユーザの ON/OFF 設定: UserDefaults `cloud_sync_enabled`
- 初回起動時: CloudSyncOnboardingView で選択
- ON/OFF 切替は ModelContainer の起動時固定のため、変更後はアプリ再起動を要求
