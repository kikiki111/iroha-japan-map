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

    /// Whether this trip consists of a single visit.
    var isSingleVisit: Bool { visits.count == 1 }

    /// Unique prefecture names visited on this trip, in chronological order.
    var prefectureNames: [String] {
        var seen = Set<String>()
        return visits.sorted { $0.startDate < $1.startDate }
            .compactMap { visit in
                seen.insert(visit.prefectureName).inserted ? visit.prefectureName : nil
            }
    }
}
