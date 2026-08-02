//
//  TripDetector.swift
//  Iroha
//

import Foundation
import SwiftData

/// Detects distinct trips from a list of visits.
///
/// Two visits belong to the same trip when they are separated by 3 days or fewer
/// (based on calendar day difference).
///
/// - Important: 居住記録 (`Visit.isResidence`) は入口で除外する。居住は期間が数年に
///   及ぶため、3 日ルールの隣接判定に混ぜると居住期間中の全旅行が 1 つの巨大な
///   Trip に併合されてしまう。ここが旅数・移動距離・タイムライン・バッジ 3 種
///   (`multiPrefTrip` / `longJourney` / `grandTour`) の共通防御点。
enum TripDetector {
    /// 同一の旅とみなす日数の上限。この日数以内に隣接する訪問は 1 つの Trip にまとめる。
    private static let sameTripDayThreshold = 3

    /// Groups `visits` into `Trip` objects using a ≤3-day interval rule.
    /// - Parameter visits: An unsorted or sorted list of visits. 居住記録は無視される。
    /// - Returns: An array of `Trip` values in chronological order.
    static func detect(from visits: [Visit]) -> [Trip] {
        let travelVisits = visits.filter { !$0.isResidence }

        // 日付が曖昧な記録 (`.month` / `.year`) は代表日 (月末 / 12/31) が実際の訪問日と
        // 一致しないため、3 日ルールの隣接判定から完全に切り離す。時系列の途中に混ざると、
        // その前後にある確定日付どうしの連結まで分断してしまうため、群ごと分ける。
        // (例:「5/1 東京」「2015年 北海道 (=12/31)」「5/3 千葉」で東京と千葉が割れる)
        let confirmed = travelVisits.filter { !$0.isDateAmbiguous }
        let ambiguous = travelVisits.filter { $0.isDateAmbiguous }

        var groups = groupByInterval(confirmed.sorted(by: chronological))
        // 曖昧な記録は常に単独の Trip とする
        groups.append(contentsOf: ambiguous.sorted(by: chronological).map { [$0] })

        return groups.map { group -> Trip in
            let uuidString = deterministicUUID(from: seed(for: group))
            guard let tripID = UUID(uuidString: uuidString) else {
                fatalError("deterministicUUID produced invalid UUID string: \(uuidString)")
            }
            return Trip(id: tripID, visits: group)
        }
    }

    // MARK: - Private helpers

    /// 同一代表日の記録が複数あっても順序がぶれないよう、県名をタイブレーカーにする。
    private static func chronological(_ lhs: Visit, _ rhs: Visit) -> Bool {
        if lhs.startDate != rhs.startDate { return lhs.startDate < rhs.startDate }
        return lhs.prefectureName < rhs.prefectureName
    }

    /// 日付昇順に並んだ訪問を、3 日ルールで隣接グループに分割する。
    private static func groupByInterval(_ sortedVisits: [Visit]) -> [[Visit]] {
        guard !sortedVisits.isEmpty else { return [] }

        var groups: [[Visit]] = []
        var currentGroup: [Visit] = [sortedVisits[0]]
        for index in 1..<sortedVisits.count {
            let previous = sortedVisits[index - 1].effectiveEndDate
            let current  = sortedVisits[index].startDate
            let days = Calendar.current.dateComponents([.day], from: previous, to: current).day
            if let days, days <= sameTripDayThreshold {
                currentGroup.append(sortedVisits[index])
            } else {
                groups.append(currentGroup)
                currentGroup = [sortedVisits[index]]
            }
        }
        groups.append(currentGroup)
        return groups
    }

    /// Trip の決定的 ID を作るための seed。
    ///
    /// 「県名 + 代表日」を seed にすると、同一県・同一年の曖昧な記録 (`.year` はどちらも
    /// 12/31 に丸まる) で ID が完全に衝突し、`sheet(item:)` が片方しか開けなくなる。
    /// `Trip.id` は永続化されない実行時限りの識別子なので、グループを構成する
    /// `persistentModelID` をハッシュして一意性を担保する。
    /// (`String(describing:)` は未保存オブジェクトで同一表現になり区別できない)
    private static func seed(for group: [Visit]) -> Int {
        var hasher = Hasher()
        for visit in group {
            hasher.combine(visit.persistentModelID)
        }
        return hasher.finalize()
    }

    /// Fixed node bytes used to distinguish Iroha-generated deterministic UUIDs.
    private static let deterministicNodeBytes: [UInt8] = [0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45]

    /// Builds a UUID string deterministically from `seed` using FNV-1a hashing.
    private static func deterministicUUID(from seed: Int) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in withUnsafeBytes(of: UInt64(bitPattern: Int64(seed)), Array.init) {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        let hi = UInt32(hash >> 32)
        let lo = UInt32(hash & 0xFFFF_FFFF)
        let timeLow   = hi
        let timeMid   = UInt16(lo >> 16)
        let timeHiVer = UInt16((lo & 0xFFFF) | 0x4000)
        let clockHi   = UInt8((hi >> 8) & 0x3F) | 0x80
        let clockLow  = UInt8(hi & 0xFF)
        let node      = deterministicNodeBytes
        return String(format: "%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                      timeLow, timeMid, timeHiVer,
                      clockHi, clockLow,
                      node[0], node[1], node[2], node[3], node[4], node[5])
    }
}
