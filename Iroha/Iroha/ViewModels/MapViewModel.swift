//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI

/// 地図と他の画面を連携させるビューモデル
@Observable
@MainActor
final class MapViewModel {
    /// 現在フォーカスされている都道府県
    private(set) var focusedPrefecture: Prefecture?

    // MARK: - Focus

    func focus(prefecture: Prefecture) {
        focusedPrefecture = prefecture
    }

    func clearFocus() {
        focusedPrefecture = nil
    }

    // MARK: - Coloring

    /// 全47都道府県を訪問済みかどうかを判定する
    func isAllVisited(prefectures: [Prefecture]) -> Bool {
        prefectures.count == 47 && prefectures.allSatisfy { $0.isVisited }
    }

    /// 訪問回数に応じた都道府県の表示色を返す
    func color(for prefecture: Prefecture, allPrefectures: [Prefecture]) -> Color {
        if isAllVisited(prefectures: allPrefectures) { return Color(hex: "#534AB7") }
        return prefecture.visitColor()
    }

    // MARK: - Statistics

    /// 地方ごとの訪問進捗
    struct RegionProgress: Identifiable {
        let region: Region
        let visited: Int
        let total: Int
        var id: Region { region }
        var ratio: Double { total > 0 ? Double(visited) / Double(total) : 0 }
    }

    /// 訪問済み都道府県数
    func visitedPrefectureCount(prefectures: [Prefecture]) -> Int {
        prefectures.filter(\.isVisited).count
    }

    /// 全訪問回数の合計
    func totalVisitCount(prefectures: [Prefecture]) -> Int {
        prefectures.reduce(0) { $0 + $1.visitCount }
    }

    /// 達成率（0.0〜1.0）
    func achievementRatio(prefectures: [Prefecture]) -> Double {
        Double(visitedPrefectureCount(prefectures: prefectures)) / 47.0
    }

    /// 8地方それぞれの訪問進捗リスト
    func regionProgressList(prefectures: [Prefecture]) -> [RegionProgress] {
        Region.allCases.map { region in
            let group = prefectures.filter { $0.region == region }
            return RegionProgress(
                region: region,
                visited: group.filter(\.isVisited).count,
                total: group.count
            )
        }
    }
}
