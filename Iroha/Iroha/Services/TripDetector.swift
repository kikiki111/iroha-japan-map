//
//  TripDetector.swift
//  Iroha
//

import Foundation

/// Detects distinct trips from a list of visits.
///
/// Two visits belong to the same trip when they are separated by 3 days or fewer
/// (based on calendar day difference).
enum TripDetector {
    /// Groups `visits` into `Trip` objects using a ≤3-day interval rule.
    /// - Parameter visits: An unsorted or sorted list of visits.
    /// - Returns: An array of `Trip` values in chronological order.
    static func detect(from visits: [Visit]) -> [Trip] {
        let sorted = visits.sorted { $0.startDate < $1.startDate }
        guard !sorted.isEmpty else { return [] }

        var groups: [[Visit]] = []
        var currentGroup: [Visit] = [sorted[0]]

        for index in 1..<sorted.count {
            let previous = sorted[index - 1].effectiveEndDate
            let current  = sorted[index].startDate
            let days = Calendar.current.dateComponents([.day], from: previous, to: current).day
            // Treat a nil result (pathological calendar state) as a trip boundary to
            // avoid silently merging visits whose interval cannot be determined.
            if let days, days <= 3 {
                currentGroup.append(sorted[index])
            } else {
                groups.append(currentGroup)
                currentGroup = [sorted[index]]
            }
        }
        groups.append(currentGroup)

        return groups.map { group -> Trip in
            let seed = "\(group[0].prefectureName)|\(group[0].startDate.timeIntervalSinceReferenceDate)"
            let tripID = UUID(uuidString: deterministicUUID(from: seed)) ?? UUID()
            return Trip(id: tripID, visits: group)
        }
    }

    // MARK: - Private helpers

    /// Fixed node bytes used to distinguish Iroha-generated deterministic UUIDs.
    private static let deterministicNodeBytes: [UInt8] = [0xAB, 0xCD, 0xEF, 0x01, 0x23, 0x45]

    /// Builds a UUID string deterministically from `seed` using FNV-1a hashing.
    private static func deterministicUUID(from seed: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in seed.utf8 {
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
