//
//  DistanceCalculator.swift
//  Iroha
//

import Foundation

enum DistanceCalculator {
    /// Haversine 公式で2地点間の直線距離（km）を計算
    static func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }

    /// 基準都道府県からの距離を計算
    static func distance(from home: Prefecture, to target: Prefecture) -> Double {
        distance(lat1: home.latitude, lon1: home.longitude,
                 lat2: target.latitude, lon2: target.longitude)
    }

    /// 旅行全体の移動距離を計算（居住地→各県→居住地のルート距離合計）
    static func totalRouteDistance(trips: [Trip], home: Prefecture, prefectures: [Prefecture]) -> Double {
        var total = 0.0

        for trip in trips {
            let sorted = trip.visits.sorted { $0.startDate < $1.startDate }
            var stops: [Prefecture] = []
            var seen = Set<String>()
            for visit in sorted {
                if seen.insert(visit.prefectureName).inserted,
                   let pref = prefectures.first(where: { $0.name == visit.prefectureName }) {
                    stops.append(pref)
                }
            }
            guard !stops.isEmpty else { continue }

            // 居住地 → 最初の県
            total += distance(from: home, to: stops[0])
            // 県 → 県
            for i in 1..<stops.count {
                total += distance(from: stops[i - 1], to: stops[i])
            }
            // 最後の県 → 居住地
            total += distance(from: stops[stops.count - 1], to: home)
        }

        return total
    }
}
