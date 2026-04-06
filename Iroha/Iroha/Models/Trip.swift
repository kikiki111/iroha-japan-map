//
//  Trip.swift
//  Iroha
//

import Foundation

/// 連続する訪問をまとめた旅行グループ
struct Trip: Identifiable {
    let id: UUID
    let visits: [Visit]

    /// 旅行の開始日（最も早い訪問日）
    var startDate: Date {
        visits.map { $0.date }.min() ?? Date()
    }

    /// 旅行の終了日（最も遅い訪問日）
    var endDate: Date {
        visits.map { $0.date }.max() ?? Date()
    }

    /// 訪問した都道府県の一覧（重複なし）
    var prefectureNames: [String] {
        Array(Set(visits.map { $0.prefectureName })).sorted()
    }
}
