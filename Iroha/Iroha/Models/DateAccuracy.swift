//
//  DateAccuracy.swift
//  Iroha
//

import Foundation

/// 旅行日の入力粒度。
///
/// 昔の旅行など「年しか覚えていない」記録を残せるようにするための精度指定。
/// 曖昧な記録 (`.month` / `.year`) でも `Visit.startDate` は `Date` のまま保持し、
/// 「代表日」に丸めて格納する (`.month` → その月の末日 / `.year` → その年の 12/31)。
/// これにより `@Query(sort: \Visit.startDate)` や年フィルタを一切変更せずに済む。
///
/// - Note: 居住記録 (`Visit.isResidence`) は対象外。居住は `residencePeriodText` で
///   既に年月粒度の表示を持つため、常に `.day` で保存する。
enum DateAccuracy: String, Codable, CaseIterable, Comparable {
    /// 年月日まで確定 (既定)
    case day   = "day"
    /// 年月まで確定 (日は不明)
    case month = "month"
    /// 年のみ確定 (月日とも不明)
    case year  = "year"

    /// 粗さ。値が大きいほど曖昧。`Comparable` と `Trip` の精度集約 (`max()`) で使う。
    private var coarseness: Int {
        switch self {
        case .day:   return 0
        case .month: return 1
        case .year:  return 2
        }
    }

    static func < (lhs: DateAccuracy, rhs: DateAccuracy) -> Bool {
        lhs.coarseness < rhs.coarseness
    }

    /// 曖昧 (日が確定していない) か。
    /// 旅の自動グルーピング・泊数・「◯年前の今日」の除外判定に使う。
    var isAmbiguous: Bool { self != .day }

    /// 月が確定しているか。四季判定・12ヶ月判定の対象可否に使う。
    /// `.month` は代表日こそ月末だが月成分は正しいため `true`。
    var hasMonth: Bool { self != .year }

    /// 入力フォームの精度セグメントに出すラベル
    var displayName: String {
        switch self {
        case .day:   return "年月日"
        case .month: return "年月"
        case .year:  return "年"
        }
    }
}

// MARK: - 代表日の正規化

extension DateAccuracy {

    /// 入力された日付を、この精度における「代表日」に丸める。
    ///
    /// - `.day`   … そのまま返す。既存データは時刻成分を持っており、`startOfDay` に
    ///   丸めると `TripDetector` の日数差や同日判定が微妙に変わるため触らない。
    /// - `.month` … その月の末日 00:00
    /// - `.year`  … その年の 12/31 00:00
    ///
    /// ただし結果が `now` より後になる場合は `now` の当日にクランプする。
    /// 今年を「年のみ」で記録したとき 12/31 (未来日) が入ると、旅行グラフが未来に
    /// 伸びる・「◯年前の今日」が負になる、といった破綻が起きるため。
    ///
    /// 月の末日はハードコードしない (うるう年バグの温床)。
    /// `Calendar.dateInterval(of:for:)` が返す「翌月/翌年の開始」から 1 日引いて求める。
    ///
    /// - Parameters:
    ///   - date: 丸める対象の日付
    ///   - now: 未来日クランプの基準。既定は現在時刻 (テスト・プレビューで固定できる)
    func normalized(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Date {
        let representative: Date
        switch self {
        case .day:
            return date
        case .month:
            representative = Self.lastDay(of: .month, containing: date, calendar: calendar) ?? date
        case .year:
            representative = Self.lastDay(of: .year, containing: date, calendar: calendar) ?? date
        }

        // 未来日クランプ。今日を含む月・年を指定したときだけ効く。
        let today = calendar.startOfDay(for: now)
        return min(representative, today)
    }

    /// `component` (月 or 年) の末日 00:00 を返す。
    private static func lastDay(
        of component: Calendar.Component,
        containing date: Date,
        calendar: Calendar
    ) -> Date? {
        guard let interval = calendar.dateInterval(of: component, for: date),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end) else {
            return nil
        }
        return calendar.startOfDay(for: lastDay)
    }

    /// 2 つの日付がこの精度で「同一」とみなせるか。
    /// 帰着日を nil (= 日帰り / 単一の記録) に畳むかの判定に使う。
    func isSame(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .day:   return calendar.isDate(lhs, inSameDayAs: rhs)
        case .month: return calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
        case .year:  return calendar.isDate(lhs, equalTo: rhs, toGranularity: .year)
        }
    }
}
