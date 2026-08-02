//
//  Trip.swift
//  Iroha
//

import Foundation

/// A group of consecutive visits detected as belonging to the same trip.
struct Trip: Identifiable, Equatable {
    static func == (lhs: Trip, rhs: Trip) -> Bool { lhs.id == rhs.id }

    let id: UUID
    let visits: [Visit]

    // MARK: - Computed properties

    /// The earliest visit date.
    ///
    /// - Note: `TripDetector` always constructs `Trip` with a non-empty `visits` array,
    ///   so the `.distantPast` fallback is purely defensive and should never be reached.
    var startDate: Date {
        visits.map(\.startDate).min() ?? .distantPast
    }

    /// The latest visit end date.
    ///
    /// - Note: `TripDetector` always constructs `Trip` with a non-empty `visits` array,
    ///   so the `.distantFuture` fallback is purely defensive and should never be reached.
    var endDate: Date {
        visits.map(\.effectiveEndDate).max() ?? .distantFuture
    }

    /// Whether this trip consists of a single visit **record**.
    ///
    /// - Important: 「県が 1 つ」ではない。1 レコードに複数県を登録できるため、
    ///   `isSingleVisit == true` かつ `prefectureNames.count > 1` はあり得る。
    var isSingleVisit: Bool { visits.count == 1 }

    /// この旅の日付精度。
    ///
    /// 曖昧な記録は `TripDetector` により常に単独 Trip になるため実質は唯一の visit の
    /// 精度と一致するが、防御的に最も粗い精度を採用する。
    var dateAccuracy: DateAccuracy {
        visits.map(\.effectiveDateAccuracy).max() ?? .day
    }

    /// 日付が曖昧（日が確定していない）旅か。
    var isDateAmbiguous: Bool { dateAccuracy.isAmbiguous }

    /// 泊数。曖昧な日付では算出しない（nil）。
    /// 「N泊M日」表示と `longJourney` バッジはこの nil を見て除外する。
    var nightCount: Int? {
        guard !isDateAmbiguous else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end   = calendar.startOfDay(for: endDate)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    var tripName: String {
        visits.sorted { $0.startDate < $1.startDate }
            .first(where: { !$0.tripName.isEmpty })?.tripName ?? ""
    }

    /// Unique prefecture names visited on this trip, in chronological order.
    /// 1 レコードに複数県がある場合はレコード内の登録順 (= 訪問順) を保って展開する。
    var prefectureNames: [String] {
        var seen = Set<String>()
        return visits.sorted { $0.startDate < $1.startDate }
            .flatMap(\.effectivePrefectureNames)
            .filter { seen.insert($0).inserted }
    }
}
