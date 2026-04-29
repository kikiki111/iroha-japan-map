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

## データモデル（SwiftData）

### Prefecture（永続化）
- id: Int（都道府県コード 1〜47）
- name, nameKana, region, latitude, longitude, distanceFromTokyo
- visits: [Visit]（@Relationship, cascade delete）
- computed: isVisited, visitCount, latestVisit

### Visit（永続化）
- prefectureName, startDate, endDate, note
- tag: VisitTag?（日帰り / 宿泊 / 居住）
- mood: VisitMood?（楽 / 癒 / 感 / 驚 / 懐 / 静）
- photoFilenames, photoThumbnails（複数写真対応）
- prefecture: Prefecture?（逆参照）

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
- PhotoStorageManager — 写真保存・読込・削除・サムネイル生成（Documents/Photos/）
- MemoryNotificationManager — 「今日の記憶」通知スケジュール（UNCalendarNotificationTrigger）
- ShareManager — 訪問マップ画像シェア（ImageRenderer + UIActivityViewController）
