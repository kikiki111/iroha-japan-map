# Iroha アーキテクチャ設計

## 画面構成
ContentView
  ├── JapanMapView （地図・Canvas 描画・アニメーション）
  ├── StatsBarView （訪問数・達成率・地方別バー）
  └── TimelineView （タイムライン・年間サマリー・旅ルート）

## データフロー
GeoJSON → GeoJSONParser → [PrefectureShape]
                                 ↓
Prefecture（SwiftData）←→ MapViewModel → JapanMapView
                                 ↓
                          TimelineViewModel → TimelineView

## タップ処理の流れ
1. タップ座標を取得（onTapGesture）
2. すべての都道府県 CGPath にヒットテスト
3. 一致した県に Visit を追加
4. visitColor() で色を再計算
5. マイルストーンチェック → アニメーション実行

## 旅ルート自動検出アルゴリズム
1. 全 Visit を日付でソート
2. 前後の Visit が 3日以内 → 同じ旅行グループ
3. グループを「旅行」として Timeline に表示
