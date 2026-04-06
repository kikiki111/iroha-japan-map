//
//  Trip.swift
//  Iroha
//

import Foundation

/// A group of consecutive visits detected as belonging to the same trip.
struct Trip: Identifiable {
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
        visits.map(\.endDate).max() ?? .distantFuture
    }

    /// Unique prefecture names visited on this trip, sorted alphabetically.
    var prefectureNames: [String] {
        Array(Set(visits.map(\.prefectureName))).sorted()
    }
}
