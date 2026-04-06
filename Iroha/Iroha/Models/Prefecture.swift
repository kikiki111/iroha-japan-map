//
//  Prefecture.swift
//  Iroha
//

import Foundation
import CoreLocation

struct Prefecture: Identifiable, Hashable {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
    /// Approximate straight-line distance from Tokyo (km)
    let distanceFromTokyo: Double

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Prefecture, rhs: Prefecture) -> Bool {
        lhs.id == rhs.id
    }
}

extension Prefecture {
    /// All 47 prefectures with prefecture-capital coordinates and distance from Tokyo.
    static let all: [Prefecture] = [
        Prefecture(id:  1, name: "北海道", coordinate: .init(latitude: 43.0642, longitude: 141.3469), distanceFromTokyo: 832),
        Prefecture(id:  2, name: "青森県", coordinate: .init(latitude: 40.8245, longitude: 140.7400), distanceFromTokyo: 677),
        Prefecture(id:  3, name: "岩手県", coordinate: .init(latitude: 39.7036, longitude: 141.1527), distanceFromTokyo: 570),
        Prefecture(id:  4, name: "宮城県", coordinate: .init(latitude: 38.2688, longitude: 140.8721), distanceFromTokyo: 346),
        Prefecture(id:  5, name: "秋田県", coordinate: .init(latitude: 39.7186, longitude: 140.1023), distanceFromTokyo: 478),
        Prefecture(id:  6, name: "山形県", coordinate: .init(latitude: 38.2404, longitude: 140.3633), distanceFromTokyo: 362),
        Prefecture(id:  7, name: "福島県", coordinate: .init(latitude: 37.7500, longitude: 140.4676), distanceFromTokyo: 266),
        Prefecture(id:  8, name: "茨城県", coordinate: .init(latitude: 36.3418, longitude: 140.4468), distanceFromTokyo: 108),
        Prefecture(id:  9, name: "栃木県", coordinate: .init(latitude: 36.5658, longitude: 139.8836), distanceFromTokyo: 109),
        Prefecture(id: 10, name: "群馬県", coordinate: .init(latitude: 36.3912, longitude: 139.0608), distanceFromTokyo: 120),
        Prefecture(id: 11, name: "埼玉県", coordinate: .init(latitude: 35.8570, longitude: 139.6489), distanceFromTokyo:  40),
        Prefecture(id: 12, name: "千葉県", coordinate: .init(latitude: 35.6051, longitude: 140.1233), distanceFromTokyo:  40),
        Prefecture(id: 13, name: "東京都", coordinate: .init(latitude: 35.6762, longitude: 139.6503), distanceFromTokyo:   0),
        Prefecture(id: 14, name: "神奈川県", coordinate: .init(latitude: 35.4478, longitude: 139.6425), distanceFromTokyo: 35),
        Prefecture(id: 15, name: "新潟県", coordinate: .init(latitude: 37.9026, longitude: 139.0232), distanceFromTokyo: 251),
        Prefecture(id: 16, name: "富山県", coordinate: .init(latitude: 36.6953, longitude: 137.2113), distanceFromTokyo: 260),
        Prefecture(id: 17, name: "石川県", coordinate: .init(latitude: 36.5944, longitude: 136.6256), distanceFromTokyo: 321),
        Prefecture(id: 18, name: "福井県", coordinate: .init(latitude: 36.0652, longitude: 136.2216), distanceFromTokyo: 349),
        Prefecture(id: 19, name: "山梨県", coordinate: .init(latitude: 35.6635, longitude: 138.5685), distanceFromTokyo: 129),
        Prefecture(id: 20, name: "長野県", coordinate: .init(latitude: 36.6513, longitude: 138.1810), distanceFromTokyo: 210),
        Prefecture(id: 21, name: "岐阜県", coordinate: .init(latitude: 35.3912, longitude: 136.7223), distanceFromTokyo: 322),
        Prefecture(id: 22, name: "静岡県", coordinate: .init(latitude: 34.9769, longitude: 138.3831), distanceFromTokyo: 183),
        Prefecture(id: 23, name: "愛知県", coordinate: .init(latitude: 35.1802, longitude: 136.9066), distanceFromTokyo: 270),
        Prefecture(id: 24, name: "三重県", coordinate: .init(latitude: 34.7303, longitude: 136.5086), distanceFromTokyo: 372),
        Prefecture(id: 25, name: "滋賀県", coordinate: .init(latitude: 35.0045, longitude: 135.8686), distanceFromTokyo: 423),
        Prefecture(id: 26, name: "京都府", coordinate: .init(latitude: 35.0116, longitude: 135.7681), distanceFromTokyo: 453),
        Prefecture(id: 27, name: "大阪府", coordinate: .init(latitude: 34.6937, longitude: 135.5023), distanceFromTokyo: 502),
        Prefecture(id: 28, name: "兵庫県", coordinate: .init(latitude: 34.6913, longitude: 135.1830), distanceFromTokyo: 556),
        Prefecture(id: 29, name: "奈良県", coordinate: .init(latitude: 34.6851, longitude: 135.8050), distanceFromTokyo: 461),
        Prefecture(id: 30, name: "和歌山県", coordinate: .init(latitude: 34.2260, longitude: 135.1675), distanceFromTokyo: 519),
        Prefecture(id: 31, name: "鳥取県", coordinate: .init(latitude: 35.5036, longitude: 134.2383), distanceFromTokyo: 624),
        Prefecture(id: 32, name: "島根県", coordinate: .init(latitude: 35.4723, longitude: 133.0505), distanceFromTokyo: 754),
        Prefecture(id: 33, name: "岡山県", coordinate: .init(latitude: 34.6618, longitude: 133.9344), distanceFromTokyo: 654),
        Prefecture(id: 34, name: "広島県", coordinate: .init(latitude: 34.3963, longitude: 132.4596), distanceFromTokyo: 723),
        Prefecture(id: 35, name: "山口県", coordinate: .init(latitude: 34.1860, longitude: 131.4705), distanceFromTokyo: 841),
        Prefecture(id: 36, name: "徳島県", coordinate: .init(latitude: 34.0658, longitude: 134.5593), distanceFromTokyo: 637),
        Prefecture(id: 37, name: "香川県", coordinate: .init(latitude: 34.3401, longitude: 134.0434), distanceFromTokyo: 670),
        Prefecture(id: 38, name: "愛媛県", coordinate: .init(latitude: 33.8417, longitude: 132.7657), distanceFromTokyo: 757),
        Prefecture(id: 39, name: "高知県", coordinate: .init(latitude: 33.5597, longitude: 133.5311), distanceFromTokyo: 784),
        Prefecture(id: 40, name: "福岡県", coordinate: .init(latitude: 33.6064, longitude: 130.4181), distanceFromTokyo: 1051),
        Prefecture(id: 41, name: "佐賀県", coordinate: .init(latitude: 33.2494, longitude: 130.2988), distanceFromTokyo: 1099),
        Prefecture(id: 42, name: "長崎県", coordinate: .init(latitude: 32.7503, longitude: 129.8777), distanceFromTokyo: 1197),
        Prefecture(id: 43, name: "熊本県", coordinate: .init(latitude: 32.7898, longitude: 130.7417), distanceFromTokyo: 1110),
        Prefecture(id: 44, name: "大分県", coordinate: .init(latitude: 33.2382, longitude: 131.6126), distanceFromTokyo: 1015),
        Prefecture(id: 45, name: "宮崎県", coordinate: .init(latitude: 31.9111, longitude: 131.4239), distanceFromTokyo: 1109),
        Prefecture(id: 46, name: "鹿児島県", coordinate: .init(latitude: 31.5602, longitude: 130.5581), distanceFromTokyo: 1201),
        Prefecture(id: 47, name: "沖縄県", coordinate: .init(latitude: 26.2124, longitude: 127.6809), distanceFromTokyo: 1555),
    ]

    /// Find a prefecture by its name.
    static func find(byName name: String) -> Prefecture? {
        all.first { $0.name == name }
    }
}
