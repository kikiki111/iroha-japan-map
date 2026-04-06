//
//  Prefecture.swift
//  Iroha
//

import Foundation

/// 日本の都道府県を表す値型
struct Prefecture: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String         // 日本語名（例: 北海道）
    let latitude: Double
    let longitude: Double

    // MARK: Hashable
    static func == (lhs: Prefecture, rhs: Prefecture) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: Distance

    /// 東京（35.6762°N, 139.6503°E）からのおおよその距離（メートル）
    var distanceFromTokyo: Double {
        haversineDistance(
            lat1: latitude, lon1: longitude,
            lat2: 35.6762,  lon2: 139.6503
        )
    }

    // MARK: Static data

    /// 全47都道府県
    static let all: [Prefecture] = [
        Prefecture(id:  1, name: "北海道",   latitude: 43.0642, longitude: 141.3469),
        Prefecture(id:  2, name: "青森県",   latitude: 40.8244, longitude: 140.7400),
        Prefecture(id:  3, name: "岩手県",   latitude: 39.7036, longitude: 141.1527),
        Prefecture(id:  4, name: "宮城県",   latitude: 38.2688, longitude: 140.8721),
        Prefecture(id:  5, name: "秋田県",   latitude: 39.7186, longitude: 140.1023),
        Prefecture(id:  6, name: "山形県",   latitude: 38.2404, longitude: 140.3634),
        Prefecture(id:  7, name: "福島県",   latitude: 37.7500, longitude: 140.4677),
        Prefecture(id:  8, name: "茨城県",   latitude: 36.3418, longitude: 140.4468),
        Prefecture(id:  9, name: "栃木県",   latitude: 36.5658, longitude: 139.8836),
        Prefecture(id: 10, name: "群馬県",   latitude: 36.3911, longitude: 139.0608),
        Prefecture(id: 11, name: "埼玉県",   latitude: 35.8575, longitude: 139.6487),
        Prefecture(id: 12, name: "千葉県",   latitude: 35.6050, longitude: 140.1233),
        Prefecture(id: 13, name: "東京都",   latitude: 35.6762, longitude: 139.6503),
        Prefecture(id: 14, name: "神奈川県", latitude: 35.4478, longitude: 139.6425),
        Prefecture(id: 15, name: "新潟県",   latitude: 37.9161, longitude: 139.0364),
        Prefecture(id: 16, name: "富山県",   latitude: 36.6953, longitude: 137.2113),
        Prefecture(id: 17, name: "石川県",   latitude: 36.5947, longitude: 136.6256),
        Prefecture(id: 18, name: "福井県",   latitude: 36.0652, longitude: 136.2219),
        Prefecture(id: 19, name: "山梨県",   latitude: 35.6639, longitude: 138.5684),
        Prefecture(id: 20, name: "長野県",   latitude: 36.6513, longitude: 138.1810),
        Prefecture(id: 21, name: "岐阜県",   latitude: 35.3912, longitude: 136.7223),
        Prefecture(id: 22, name: "静岡県",   latitude: 34.9769, longitude: 138.3831),
        Prefecture(id: 23, name: "愛知県",   latitude: 35.1802, longitude: 136.9066),
        Prefecture(id: 24, name: "三重県",   latitude: 34.7303, longitude: 136.5086),
        Prefecture(id: 25, name: "滋賀県",   latitude: 35.0045, longitude: 135.8685),
        Prefecture(id: 26, name: "京都府",   latitude: 35.0211, longitude: 135.7556),
        Prefecture(id: 27, name: "大阪府",   latitude: 34.6937, longitude: 135.5022),
        Prefecture(id: 28, name: "兵庫県",   latitude: 34.6913, longitude: 135.1830),
        Prefecture(id: 29, name: "奈良県",   latitude: 34.6851, longitude: 135.8048),
        Prefecture(id: 30, name: "和歌山県", latitude: 34.2260, longitude: 135.1675),
        Prefecture(id: 31, name: "鳥取県",   latitude: 35.5036, longitude: 134.2383),
        Prefecture(id: 32, name: "島根県",   latitude: 35.4723, longitude: 133.0505),
        Prefecture(id: 33, name: "岡山県",   latitude: 34.6617, longitude: 133.9344),
        Prefecture(id: 34, name: "広島県",   latitude: 34.3853, longitude: 132.4553),
        Prefecture(id: 35, name: "山口県",   latitude: 34.1860, longitude: 131.4706),
        Prefecture(id: 36, name: "徳島県",   latitude: 34.0658, longitude: 134.5593),
        Prefecture(id: 37, name: "香川県",   latitude: 34.3401, longitude: 134.0433),
        Prefecture(id: 38, name: "愛媛県",   latitude: 33.8417, longitude: 132.7657),
        Prefecture(id: 39, name: "高知県",   latitude: 33.5597, longitude: 133.5311),
        Prefecture(id: 40, name: "福岡県",   latitude: 33.5904, longitude: 130.4017),
        Prefecture(id: 41, name: "佐賀県",   latitude: 33.2494, longitude: 130.2988),
        Prefecture(id: 42, name: "長崎県",   latitude: 32.7447, longitude: 129.8737),
        Prefecture(id: 43, name: "熊本県",   latitude: 32.7898, longitude: 130.7417),
        Prefecture(id: 44, name: "大分県",   latitude: 33.2382, longitude: 131.6126),
        Prefecture(id: 45, name: "宮崎県",   latitude: 31.9111, longitude: 131.4239),
        Prefecture(id: 46, name: "鹿児島県", latitude: 31.5966, longitude: 130.5571),
        Prefecture(id: 47, name: "沖縄県",   latitude: 26.2124, longitude: 127.6809),
    ]

    /// 名前から都道府県を検索する
    static func named(_ name: String) -> Prefecture? {
        all.first { $0.name == name }
    }
}

// MARK: - Haversine distance

private func haversineDistance(lat1: Double, lon1: Double,
                               lat2: Double, lon2: Double) -> Double {
    let r = 6_371_000.0  // Earth radius in metres
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2)
          + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
          * sin(dLon / 2) * sin(dLon / 2)
    return r * 2 * atan2(sqrt(a), sqrt(1 - a))
}
