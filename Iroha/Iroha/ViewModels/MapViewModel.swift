//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI

// MARK: - MilestoneType

/// マイルストーンアニメーションの種類
enum MilestoneType: Equatable {
    /// 初訪問（0→1）
    case firstVisit(prefectureCode: Int)
    /// 半分制覇（25県）
    case halfConquest
    /// 地方制覇
    case regionConquest(Region)
    /// 全国制覇（47県）
    case nationalConquest
}

// MARK: - MapViewModel

/// 地図と他の画面を連携させるビューモデル
@Observable
@MainActor
final class MapViewModel {
    /// 現在フォーカスされている都道府県（シートバインディング用に読み書き可能）
    var focusedPrefecture: Prefecture?

    /// 現在実行中のマイルストーンアニメーション
    var pendingMilestone: MilestoneType?

    /// 地図のスケール（半分制覇アニメーション用）
    var mapScale: CGFloat = 1.0

    /// ブックマーク切り替え時のトースト表示
    var bookmarkToast: String?

    /// 行きたいリストの地図上表示
    var showBookmarks: Bool = true

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

    // MARK: - Milestone Detection

    /// 訪問保存後にマイルストーンを検出する。
    func detectMilestone(
        oldVisitedCount: Int,
        oldRegionCounts: [Region: Int],
        prefectures: [Prefecture]
    ) {
        let newVisitedCount = visitedPrefectureCount(prefectures: prefectures)

        // 優先度: national > half > region > first
        if newVisitedCount == 47, !milestoneShown("milestone_47_shown") {
            markMilestoneShown("milestone_47_shown")
            pendingMilestone = .nationalConquest
            return
        }

        if newVisitedCount >= 25, oldVisitedCount < 25, !milestoneShown("milestone_25_shown") {
            markMilestoneShown("milestone_25_shown")
            pendingMilestone = .halfConquest
            return
        }

        let newRegionCounts = regionVisitedCounts(prefectures: prefectures)
        let totals = regionTotalCounts(prefectures: prefectures)
        for region in Region.allCases {
            let oldCount = oldRegionCounts[region] ?? 0
            let newCount = newRegionCounts[region] ?? 0
            let total = totals[region] ?? 0
            if total > 0, newCount == total, oldCount < total {
                let key = "region_\(region.rawValue)_shown"
                if !milestoneShown(key) {
                    markMilestoneShown(key)
                    pendingMilestone = .regionConquest(region)
                    return
                }
            }
        }

        if newVisitedCount > oldVisitedCount {
            if let newlyVisited = prefectures.first(where: { $0.visitCount == 1 }) {
                pendingMilestone = .firstVisit(prefectureCode: newlyVisited.id)
            }
        }
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

    /// 地方ごとの訪問済み都道府県数
    func regionVisitedCounts(prefectures: [Prefecture]) -> [Region: Int] {
        var result: [Region: Int] = [:]
        for region in Region.allCases {
            result[region] = prefectures.filter { $0.region == region && $0.isVisited }.count
        }
        return result
    }

    /// 地方ごとの都道府県総数
    func regionTotalCounts(prefectures: [Prefecture]) -> [Region: Int] {
        var result: [Region: Int] = [:]
        for region in Region.allCases {
            result[region] = prefectures.filter { $0.region == region }.count
        }
        return result
    }

    // MARK: - Private

    private func milestoneShown(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    private func markMilestoneShown(_ key: String) {
        UserDefaults.standard.set(true, forKey: key)
    }
}
