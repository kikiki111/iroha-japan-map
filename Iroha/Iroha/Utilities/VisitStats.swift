//
//  VisitStats.swift
//  Iroha
//

import Foundation
import SwiftData
import SwiftUI

/// 訪問記録から都道府県ごとの訪問回数や地方制覇状況を集計するヘルパー。
///
/// `Prefecture` を SwiftData モデルから外して static struct 化したため、
/// 訪問状態 (`isVisited` / `visitCount` 等) は `Visit` 群から動的に算出する。
/// View では `@Query var visits: [Visit]` を取得し、`VisitStats(visits: visits)` を
/// 1 度作ってサブビューや判定で使う。
struct VisitStats {
    /// 旅行回数のみ。居住は「5年住んだ = 1回訪問」とはしないため加算しない。
    /// 1 レコードに複数県が入っている場合は各県に 1 ずつ加算する (全県を等しくカウント)。
    let countsByPrefectureID: [Int: Int]
    /// 訪問済み扱いの都道府県 ID。旅行 1 回以上 **または** 居住あり。
    let visitedIDs: Set<Int>
    /// 居住したことのある都道府県 ID。
    let residenceIDs: Set<Int>

    init(visits: [Visit]) {
        // 既知 (1〜47) の prefectureID のみを集計対象とする。
        // prefectureID == 0 (未 backfill) や不正な値は除外。
        let validIDs = Set(Prefecture.all.map(\.id))
        var counts: [Int: Int] = [:]
        var residences: Set<Int> = []
        for visit in visits where !visit.isDeleted {
            // 1 レコードが複数県を持つため二重ループ。旅行 / 居住の振り分けは
            // 県ごとに行う (この分岐を落とすと residenceIDs が空になり、
            // 統計バーの家アイコンと地図の居住専用色が消える)。
            let isResidence = visit.isResidence
            for id in visit.effectivePrefectureIDs where validIDs.contains(id) {
                if isResidence {
                    residences.insert(id)
                } else {
                    counts[id, default: 0] += 1
                }
            }
        }
        self.countsByPrefectureID = counts
        self.residenceIDs = residences
        // 居住県も「訪問済み」に含める (住んだ県を未訪問扱いにしない)
        self.visitedIDs = Set(counts.keys).union(residences)
    }

    /// 任意の `Visit` 群を都道府県 ID でグルーピングする (1 レコードが複数県に属しうる)。
    ///
    /// `Dictionary(grouping:by:)` は「1 レコード = 1 キー」前提で複数県に使えないため、
    /// 母集団を限定した集計 (バッジ判定・期間フィルタ後の最多県など) はこちらを使う。
    /// 母集団は呼び出し側ごとに違う (全件 / 旅行のみ / 月が既知の旅行のみ) ので、
    /// インスタンスに辞書を持たせず、対象配列を引数で受け取る。
    static func groupedByPrefectureID(_ visits: [Visit]) -> [Int: [Visit]] {
        var grouped: [Int: [Visit]] = [:]
        for visit in visits {
            for id in visit.effectivePrefectureIDs {
                grouped[id, default: []].append(visit)
            }
        }
        return grouped
    }

    /// 住んだことのある都道府県数。
    var residenceCount: Int { residenceIDs.count }

    func isResidence(_ prefecture: Prefecture) -> Bool {
        residenceIDs.contains(prefecture.id)
    }

    func isResidence(prefectureID id: Int) -> Bool {
        residenceIDs.contains(id)
    }

    func count(for prefecture: Prefecture) -> Int {
        countsByPrefectureID[prefecture.id] ?? 0
    }

    func count(forPrefectureID id: Int) -> Int {
        countsByPrefectureID[id] ?? 0
    }

    func isVisited(_ prefecture: Prefecture) -> Bool {
        visitedIDs.contains(prefecture.id)
    }

    func isVisited(prefectureID id: Int) -> Bool {
        visitedIDs.contains(id)
    }

    var visitedPrefectures: [Prefecture] {
        Prefecture.all.filter { visitedIDs.contains($0.id) }
    }

    var visitedCount: Int { visitedIDs.count }

    var isAllVisited: Bool { visitedIDs.count == 47 }

    /// 地方ごとの訪問済み都道府県数。
    func visitsByRegion() -> [Region: Int] {
        var counts: [Region: Int] = [:]
        for prefecture in visitedPrefectures {
            counts[prefecture.region, default: 0] += 1
        }
        return counts
    }

    /// 指定地方が制覇 (全都道府県訪問) されているか。
    func isRegionConquered(_ region: Region) -> Bool {
        let prefsInRegion = Prefecture.all.filter { $0.region == region }
        guard !prefsInRegion.isEmpty else { return false }
        return prefsInRegion.allSatisfy { visitedIDs.contains($0.id) }
    }

    /// 訪問済み都道府県のうち、東京から最も遠いもの。
    func farthestVisitedPrefecture() -> Prefecture? {
        visitedPrefectures.max { $0.distanceFromTokyo < $1.distanceFromTokyo }
    }

    /// SwiftUI の `onChange` 用の signature。件数だけでなく
    /// prefectureID 分布の変化 (訪問先編集など) も検知できる。
    ///
    /// - Important: Swift の `Hasher` はプロセス起動ごとに seed が変わるため、
    ///   永続化・snapshot 比較・プロセス間比較には使わない。`onChange` 限定。
    var signature: Int {
        var hasher = Hasher()
        for id in countsByPrefectureID.keys.sorted() {
            hasher.combine(id)
            hasher.combine(countsByPrefectureID[id])
        }
        // 居住のみの変更 (旅行回数が動かないケース) でも onChange を発火させる
        for id in residenceIDs.sorted() {
            hasher.combine(id)
        }
        return hasher.finalize()
    }
}

// MARK: - Color helpers (Prefecture extension から移植)

extension VisitStats {
    /// 訪問回数に応じた塗りつぶし色を返す。全国制覇時は最濃色で統一。
    func color(for prefecture: Prefecture) -> Color {
        Color(hex: colorHex(for: prefecture))
    }

    /// WebView へ渡す用の Hex 文字列。
    ///
    /// 優先順位は **旅行 > 居住**。住んだ県に旅行もしている場合は訪問回数どおりの
    /// 紫で塗り、地図から旅行回数が読み取れる状態を保つ。
    /// 居住専用色 (淡い金茶) になるのは「住んだが旅行記録は 1 件もない」県のみ。
    func colorHex(for prefecture: Prefecture) -> String {
        if isAllVisited { return "#534AB7" }
        if count(for: prefecture) == 0, isResidence(prefecture) {
            return Color.residenceHex
        }
        switch count(for: prefecture) {
        case 0:    return "#DDDAD4"
        case 1:    return "#C8C4F0"
        case 2:    return "#9F97DD"
        case 3, 4: return "#7F77DD"
        default:   return "#534AB7"
        }
    }
}
