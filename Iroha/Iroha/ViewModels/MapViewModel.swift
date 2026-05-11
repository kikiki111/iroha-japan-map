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
    /// N県達成（5/10/15/20/30/35/40/45）
    case countMilestone(count: Int)
    /// 半分制覇（25県）
    case halfConquest
    /// 地方制覇
    case regionConquest(Region)
    /// 全国制覇（47県）
    case nationalConquest
}

// MARK: - MapDisplayMode

enum MapDisplayMode: String, CaseIterable {
    case all = "旅した"
    case unvisited = "これから"
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

    /// マイルストーン達成時のトースト
    var milestoneToast: String?

    /// 地図の表示モード
    var displayMode: MapDisplayMode = .all

    /// N県マイルストーンの閾値（降順）
    static let countMilestones = [45, 40, 35, 30, 20, 15, 10, 5]

    // MARK: - Focus

    func focus(prefecture: Prefecture) {
        focusedPrefecture = prefecture
    }

    func clearFocus() {
        focusedPrefecture = nil
    }

    // MARK: - Coloring

    /// 全47都道府県を訪問済みかどうかを判定する
    func isAllVisited(stats: VisitStats) -> Bool {
        stats.isAllVisited
    }

    /// 訪問回数に応じた都道府県の表示色を返す
    func color(for prefecture: Prefecture, stats: VisitStats) -> Color {
        stats.color(for: prefecture)
    }

    // MARK: - Milestone Detection

    /// 訪問保存後にマイルストーンを検出する。
    func detectMilestone(
        oldVisitedCount: Int,
        oldRegionCounts: [Region: Int],
        stats: VisitStats
    ) {
        let newVisitedCount = stats.visitedCount

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

        let newRegionCounts = stats.visitsByRegion()
        let totals = Self.regionTotalCounts
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

        for count in Self.countMilestones {
            if newVisitedCount >= count, oldVisitedCount < count {
                let key = "milestone_\(count)_shown"
                if !milestoneShown(key) {
                    for lower in Self.countMilestones where lower <= count {
                        markMilestoneShown("milestone_\(lower)_shown")
                    }
                    pendingMilestone = .countMilestone(count: count)
                    return
                }
            }
        }

        if newVisitedCount > oldVisitedCount {
            // 直近で +1 された県を特定 (count == 1 の県)
            if let newlyVisited = Prefecture.all.first(where: { stats.count(for: $0) == 1 }) {
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
    func visitedPrefectureCount(stats: VisitStats) -> Int {
        stats.visitedCount
    }

    /// 全訪問回数の合計
    func totalVisitCount(stats: VisitStats) -> Int {
        stats.countsByPrefectureID.values.reduce(0, +)
    }

    /// 達成率（0.0〜1.0）
    func achievementRatio(stats: VisitStats) -> Double {
        Double(stats.visitedCount) / 47.0
    }

    /// 8地方それぞれの訪問進捗リスト
    func regionProgressList(stats: VisitStats) -> [RegionProgress] {
        let totals = Self.regionTotalCounts
        let visited = stats.visitsByRegion()
        return Region.allCases.map { region in
            RegionProgress(
                region: region,
                visited: visited[region] ?? 0,
                total: totals[region] ?? 0
            )
        }
    }

    /// 地方ごとの訪問済み都道府県数
    func regionVisitedCounts(stats: VisitStats) -> [Region: Int] {
        var result: [Region: Int] = [:]
        let visited = stats.visitsByRegion()
        for region in Region.allCases {
            result[region] = visited[region] ?? 0
        }
        return result
    }

    /// 地方ごとの都道府県総数（Prefecture.all から事前計算）
    static let regionTotalCounts: [Region: Int] = {
        var result: [Region: Int] = [:]
        for region in Region.allCases {
            result[region] = Prefecture.all.filter { $0.region == region }.count
        }
        return result
    }()

    // MARK: - Distance

    private func distanceFromTokyo(_ target: Prefecture) -> Double {
        guard let tokyo = Prefecture.by(id: 13) else {
            return target.distanceFromTokyo
        }
        return DistanceCalculator.distance(from: tokyo, to: target)
    }

    func totalTravelDistance(visits: [Visit]) -> Int {
        guard let tokyo = Prefecture.by(id: 13) else { return 0 }
        let trips = TripDetector.detect(from: visits)
        return Int(DistanceCalculator.totalRouteDistance(trips: trips, home: tokyo, prefectures: Prefecture.all))
    }

    func farthestVisitedPrefecture(stats: VisitStats) -> Prefecture? {
        stats.visitedPrefectures.max { distanceFromTokyo($0) < distanceFromTokyo($1) }
    }

    // MARK: - Region Suggestion

    struct RegionSuggestion {
        let region: Region
        let remaining: Int
        let unvisited: [Prefecture]
    }

    func closestRegionSuggestion(stats: VisitStats) -> RegionSuggestion? {
        let progressList = regionProgressList(stats: stats)

        let inProgress = progressList
            .filter { $0.visited > 0 && $0.visited < $0.total }
            .sorted {
                let remA = $0.total - $0.visited
                let remB = $1.total - $1.visited
                if remA != remB { return remA < remB }
                return $0.ratio > $1.ratio
            }

        guard let closest = inProgress.first else { return nil }
        let unvisited = Prefecture.all
            .filter { $0.region == closest.region && !stats.isVisited($0) }
        return RegionSuggestion(
            region: closest.region,
            remaining: closest.total - closest.visited,
            unvisited: unvisited
        )
    }

    // MARK: - Private

    private func milestoneShown(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    private func markMilestoneShown(_ key: String) {
        UserDefaults.standard.set(true, forKey: key)
    }
}
