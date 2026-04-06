# Iroha アーキテクチャ設計

## 画面構成
ContentView
  ├── JapanMapView （Geolonia SVG + WKWebView で地図描画）
  ├── StatsBarView （訪問数・達成率・地方別バー）
  └── TimelineView （タイムライン・年間サマリー・旅ルート）

## データフロー
Prefecture（SwiftData）←→ MapViewModel → JapanMapView
                                 ↓
                          Visit → TripDetector → TimelineView

## タップ処理の流れ
1. SVG 上の都道府県要素を JavaScript がタップ検出
2. WKScriptMessageHandler 経由で Swift にコード送信
3. MapViewModel.focus(prefecture:) で対象を選択
4. AddVisitView シートで Visit を追加
5. visitColorHex() で色を再計算し WebView に反映

## 旅ルート自動検出アルゴリズム
1. 全 Visit を日付でソート
2. 前後の Visit が 3日以内 → 同じ旅行グループ
3. グループを「旅行」として Timeline に表示
