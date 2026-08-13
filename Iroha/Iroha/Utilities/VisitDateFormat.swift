//
//  VisitDateFormat.swift
//  Iroha
//

import Foundation

/// 旅行日の表示文字列を精度 (`DateAccuracy`) に応じて組み立てる共通フォーマッタ。
///
/// 精度導入前は `.formatted(.dateTime.year().month().day().locale(...))` が
/// 10 箇所にコピペされていた。精度ごとの出し分けを各 View に書くと破綻するため、
/// ここに集約する。
///
/// - Note: 居住記録の期間表示は `Visit.residencePeriodText` が担当する
///   (居住は精度の概念を持たず、常に年月粒度で表示する)。
enum VisitDateFormat {

    private static let japanese = Locale(identifier: "ja_JP")

    // MARK: - 単一日付

    /// 精度に応じて「2015年5月3日」/「2015年5月」/「2015年」を返す。
    static func text(_ date: Date, accuracy: DateAccuracy) -> String {
        switch accuracy {
        case .day:   return date.formatted(.dateTime.year().month().day().locale(japanese))
        case .month: return date.formatted(.dateTime.year().month().locale(japanese))
        case .year:  return date.formatted(.dateTime.year().locale(japanese))
        }
    }

    /// 2 桁ゼロ埋め版。`MemoryCardView` 専用。
    ///
    /// - Note: `.twoDigits` を指定すると ja_JP でも「2015/05/03」形式になる
    ///   (「2015年05月03日」ではない)。精度導入前からの表示なのでそのまま踏襲する。
    ///   曖昧な精度では `text(_:accuracy:)` にフォールバックするが、`MemoryCardView`
    ///   は `.day` の記録しか扱わないため実際には呼ばれない。
    static func compactText(_ date: Date, accuracy: DateAccuracy) -> String {
        guard accuracy == .day else { return text(date, accuracy: accuracy) }
        return date.formatted(
            .dateTime.year().month(.twoDigits).day(.twoDigits).locale(japanese)
        )
    }

    // MARK: - 期間

    /// 開始 〜 終了。精度上で同一なら単一表示にフォールバックする。
    /// - Parameter separator: 一覧は「〜」、入力フォームのサマリは「→」を使う。
    static func rangeText(
        from start: Date,
        to end: Date,
        accuracy: DateAccuracy,
        separator: String = "〜"
    ) -> String {
        if accuracy.isSame(start, end) {
            return text(start, accuracy: accuracy)
        }
        return "\(text(start, accuracy: accuracy)) \(separator) \(text(end, accuracy: accuracy))"
    }

    // MARK: - Visit / Trip 受け取り版

    /// 訪問の開始日。精度は `Visit` から取る。
    static func startText(_ visit: Visit) -> String {
        text(visit.startDate, accuracy: visit.effectiveDateAccuracy)
    }

    /// 訪問の期間（日帰りなら単一表示）。
    static func rangeText(_ visit: Visit, separator: String = "〜") -> String {
        rangeText(from: visit.startDate, to: visit.effectiveEndDate,
                  accuracy: visit.effectiveDateAccuracy, separator: separator)
    }

    /// 旅の期間（単日なら単一表示）。
    static func rangeText(_ trip: Trip, separator: String = "〜") -> String {
        rangeText(from: trip.startDate, to: trip.endDate,
                  accuracy: trip.dateAccuracy, separator: separator)
    }
}
