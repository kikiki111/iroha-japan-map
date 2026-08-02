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
- kind: VisitKind?（旅行 / 居住。nil = 旧データ → effectiveKind で .travel に倒す）
- startDate（旅行の開始日 / 居住の開始日）, endDate（**旅行専用**、nil = 日帰り）, note
- residenceEndDate: Date?（**居住専用**の終了日）, isResidenceOngoing: Bool（現在も居住中）
  - endDate と residenceEndDate を分けているのは、nil の意味が「日帰り」と「継続中」で衝突するため
- tag: String?（旅行スタイル ID。kind と直交する軸で、居住でも選べる。プリセットは `TravelStylePreset.rawValue`、ユーザー定義は `"u:<UUID>"`。未選択は nil で、レガシー文字列 `"none"` も未選択として扱う）
- mood: VisitMood?（楽 / 癒 / 感 / 驚 / 懐 / 静）
- transports, tripName, companions, location, locationLatitude, locationLongitude
- photos: [VisitPhoto]?（@Relationship, cascade delete, optional 必須）
- 旧 photoFilenames / photoThumbnails / photoFilename / photoThumbnail（PhotoMigration 完了確認まで併存）
- 互換ヘルパー: totalPhotoCount, sortedPhotoThumbnails, sortedPhotoFilenames, sortedPhotos
- 居住ヘルパー: effectiveKind, isResidence, residencePeriodText, residenceDurationText
- 新フィールド追加時は CloudKit 互換のため **optional か default 値付き** が必須（`kind` は optional、`isResidenceOngoing` は default false）。lightweight migration で自動処理されるため専用 Migration は不要

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
- **居住は count に加算しない**（5 年住んだのを「1 回訪問」としない）が、`visitedIDs` には含める（住んだ県を未訪問扱いにしない）
- API: count(for:), isVisited(_:), isResidence(_:), residenceCount, isAllVisited, visitedPrefectures, visitsByRegion(), isRegionConquered(_:), color(for:), colorHex(for:), signature
- `colorHex(for:)` の優先順位は **旅行 > 居住**。淡い金茶 `#E8D9A8` を返すのは「居住あり かつ 旅行 0 回」の県のみで、旅行があれば訪問回数どおりの紫になる（地図から旅行回数を読めるようにするため）
- `signature` には residenceIDs も混ぜる（居住のみの変更で onChange が発火しなくなるため）
- View 階層で 1 度作ってサブビューに渡す

### Trip（非永続化 — TripDetector で動的生成）
- visits: [Visit]
- computed: startDate, endDate, isSingleVisit, prefectureNames

### Region（enum）
hokkaido, tohoku, kanto, chubu, kinki, chugoku, shikoku, kyushu

### VisitKind（enum）
travel（旅行）, residence（居住）
- `.none` を持たない 2 値。未設定は `Visit.kind == nil`（旧データ）で表し、`effectiveKind` が `.travel` を返す

### 旅行スタイル（プリセット + ユーザー定義）

固定 enum ではなく、静的プリセットと永続レコードを 1 つの値型に投影する構成。

| 型 | 役割 |
|---|---|
| `TravelStylePreset`（enum） | アプリ標準の 5 種: solo（一人旅）, family（家族旅行）, couple（恋人旅行）, friends（友達旅行）, other（その他）。legacy 3 種（dayTrip, stay, lived）は表示専用で選択肢に出さない |
| `TravelStyleRecord`（@Model） | ユーザーが追加したカスタム行と、プリセットを非表示にしたときだけ作るオーバーレイ行。`isHidden` はどちらの行でも使い、カスタムスタイルの表示・非表示も同じフラグで表す |
| `TravelStyle`（struct） | 上記 2 つを投影した UI 用の統一型。`id` / `name` / `iconName` / `palette` |
| `TravelStyleCatalog`（struct） | プリセット + カスタムを統合した参照テーブル。`TravelStyleCatalogProvider` が `@Query` の単一オーナーとなり Environment で配る |
| `TravelStylePalette`（enum） | 伝統色ベースの配色。ユーザー選択可能な 12 色を含む |
| `TravelStyleStore`（enum） | 書き込み専用 CRUD。読み取りは `@Query` + カタログが担う |

- **プリセットは SwiftData に seed しない。** `Prefecture` と同じ理由（複数端末での seed 重複回避）
- ユーザー定義は CloudKit 同期する。`Visit.tag` が同期対象である以上、定義だけ端末ローカルに置くと他端末でバッジが消えるため
- カスタムスタイルの削除時は、該当 `Visit.tag` を nil にしてから 1 トランザクションで消す（記録自体は削除しない）

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
0. **居住記録（`isResidence`）を入口で除外**
   （居住は期間が数年に及ぶため、3 日ルールに混ぜると居住期間中の全旅行が 1 つの巨大 Trip に併合される。
   旅数・移動距離・タイムライン・バッジ 3 種の共通防御点）
1. 残った Visit を startDate でソート
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
- Schema は [Visit.self, VisitPhoto.self, TravelStyleRecord.self]（Prefecture と旅行スタイルのプリセットは静的テーブル、同期対象外）
- `TravelStyleRecord` は新しい CKRecord タイプなので、**リリース前に CloudKit Dashboard で Production へスキーマをデプロイする**
- ユーザの ON/OFF 設定: UserDefaults `cloud_sync_enabled`
- 初回起動時: CloudSyncOnboardingView で選択
- ON/OFF 切替は ModelContainer の起動時固定のため、変更後はアプリ再起動を要求
