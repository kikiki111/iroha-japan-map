//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class MapViewModel {
    var prefectures: [Prefecture] = []

    // MARK: - Animation State

    /// 半分制覇・全国制覇アニメーション用の地図スケール。
    var mapScale: Double = 1.0
    /// 地方制覇フラッシュ中の都道府県 ID セット。
    var flashingPrefectureIDs: Set<Int> = []
    /// 全国制覇ウェーブアニメーションで順番に色変化した都道府県 ID セット。
    var animatedPrefectureIDs: Set<Int> = []
    /// 全国制覇ウェーブアニメーション進行中フラグ。
    var isAnimatingFullConquest: Bool = false

    @ObservationIgnored
    private var isMilestoneAnimating = false

    // MARK: - Computed

    var visitedCount: Int {
        prefectures.filter { $0.isVisited }.count
    }

    /// 全47都道府県をすべて1回以上訪問済みかどうか。
    var isAllVisited: Bool {
        prefectures.count == 47 && prefectures.allSatisfy { $0.isVisited }
    }

    // MARK: - Color

    /// アニメーション状態・isAllVisited を考慮した都道府県の表示色を返す。
    func color(for prefecture: Prefecture) -> Color {
        if isAnimatingFullConquest {
            return animatedPrefectureIDs.contains(prefecture.id)
                ? Color(hex: "#534AB7")
                : prefecture.visitColor()
        }
        if isAllVisited {
            return Color(hex: "#534AB7")
        }
        if flashingPrefectureIDs.contains(prefecture.id) {
            return Color(hex: "#AFA9EC")
        }
        return prefecture.visitColor()
    }

    // MARK: - Visit

    /// 都道府県に訪問を追加し、マイルストーンアニメーションをチェックする。
    func addVisit(to prefecture: Prefecture, using context: ModelContext) {
        let wasVisited = prefecture.isVisited
        let visit = Visit(date: Date())
        visit.prefecture = prefecture

        if !wasVisited {
            // Animation 1: 初訪問（0→1）は easeInOut(0.4) で色変化
            withAnimation(.easeInOut(duration: 0.4)) {
                prefecture.visits.append(visit)
            }
        } else {
            prefecture.visits.append(visit)
        }
        context.insert(visit)

        checkMilestones(for: prefecture)
    }

    // MARK: - Milestone Checks

    private func checkMilestones(for prefecture: Prefecture) {
        guard !isMilestoneAnimating, prefectures.count == 47 else { return }

        let visited = visitedCount

        if visited == 47, !UserDefaults.standard.bool(forKey: "milestone_47_shown") {
            isMilestoneAnimating = true
            UserDefaults.standard.set(true, forKey: "milestone_47_shown")
            triggerFullMilestone()
            return
        }

        if visited == 25, !UserDefaults.standard.bool(forKey: "milestone_25_shown") {
            isMilestoneAnimating = true
            UserDefaults.standard.set(true, forKey: "milestone_25_shown")
            triggerHalfMilestone()
            return
        }

        let regionKey = "region_\(prefecture.region.rawValue)_shown"
        guard !UserDefaults.standard.bool(forKey: regionKey) else { return }
        let regionPrefectures = prefectures.filter { $0.region == prefecture.region }
        guard !regionPrefectures.isEmpty,
              regionPrefectures.allSatisfy({ $0.isVisited }) else { return }

        isMilestoneAnimating = true
        UserDefaults.standard.set(true, forKey: regionKey)
        triggerRegionMilestone(for: prefecture.region)
    }

    // MARK: - Animation 2: 半分制覇

    private func triggerHalfMilestone() {
        withAnimation(.easeInOut(duration: 0.8).repeatCount(1, autoreverses: true)) {
            mapScale = 1.02
        }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            mapScale = 1.0
            isMilestoneAnimating = false
        }
    }

    // MARK: - Animation 3: 地方制覇フラッシュ

    private func triggerRegionMilestone(for region: Region) {
        let regionIDs = Set(prefectures.filter { $0.region == region }.map { $0.id })
        withAnimation(.easeInOut(duration: 0.3)) {
            flashingPrefectureIDs = regionIDs
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeInOut(duration: 0.3)) {
                self.flashingPrefectureIDs = []
            }
            try? await Task.sleep(for: .seconds(0.3))
            self.isMilestoneAnimating = false
        }
    }

    // MARK: - Animation 4: 全国制覇ウェーブ

    private func triggerFullMilestone() {
        let sortedIDs = prefectures
            .sorted { $0.latitude > $1.latitude }
            .map { $0.id }
        isAnimatingFullConquest = true
        animatedPrefectureIDs = []

        Task {
            var previousDelay = 0.0
            for (index, id) in sortedIDs.enumerated() {
                let targetDelay = Double(index) / 47.0 * 3.0
                let sleepDuration = targetDelay - previousDelay
                if sleepDuration > 0 {
                    try? await Task.sleep(for: .seconds(sleepDuration))
                }
                previousDelay = targetDelay
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.animatedPrefectureIDs.insert(id)
                }
            }
            // 最後のアニメーション完了を待つ
            try? await Task.sleep(for: .seconds(0.3))
            isAnimatingFullConquest = false
            animatedPrefectureIDs = []
            isMilestoneAnimating = false
        }
    }
}
