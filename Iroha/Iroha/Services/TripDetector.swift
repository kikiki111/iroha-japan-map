//
//  TripDetector.swift
//  Iroha
//

import Foundation

/// 訪問履歴から旅行グループを自動検出するユーティリティ
enum TripDetector {
    /// 連続する訪問間の最大日数（この日数以内なら同じ旅行とみなす）
    static let maxIntervalDays = 3

    /// 訪問一覧から旅行グループ（Trip）を検出して返す
    ///
    /// - Parameter visits: 検出対象の訪問一覧（順序不問）
    /// - Returns: 日付昇順でグループ化された旅行の配列
    static func detect(from visits: [Visit]) -> [Trip] {
        let sorted = visits.sorted { $0.date < $1.date }
        var groups: [[Visit]] = []
        var currentGroup: [Visit] = []

        for visit in sorted {
            if let lastVisit = currentGroup.last {
                let interval = daysBetween(lastVisit.date, and: visit.date)
                if interval <= maxIntervalDays {
                    currentGroup.append(visit)
                } else {
                    groups.append(currentGroup)
                    currentGroup = [visit]
                }
            } else {
                currentGroup.append(visit)
            }
        }

        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups.map { Trip(id: UUID(), visits: $0) }
    }

    // MARK: - Private helpers

    private static func daysBetween(_ from: Date, and to: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: from, to: to)
        return abs(components.day ?? 0)
    }
}
