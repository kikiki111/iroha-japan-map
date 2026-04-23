//
//  Prefecture.swift
//  Iroha
//

import Foundation
import SwiftData

/// 日本の都道府県を表す SwiftData モデル
@Model
final class Prefecture {
    /// 都道府県コード（1〜47）
    var id: Int
    var name: String
    /// 読み仮名（ひらがな）
    var nameKana: String = ""
    var region: Region
    var latitude: Double
    var longitude: Double
    /// 東京からの直線距離（km）
    var distanceFromTokyo: Double
    /// 「行きたい」フラグ
    var isWanted: Bool = false
    /// 「行きたい」ブックマーク（旧名。互換性のため残す）
    var isBookmarked: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Visit.prefecture)
    var visits: [Visit] = []

    var isVisited: Bool { !visits.isEmpty }
    var visitCount: Int { visits.count }
    var latestVisit: Visit? { visits.sorted { $0.startDate > $1.startDate }.first }

    init(id: Int, name: String, nameKana: String = "", region: Region,
         latitude: Double, longitude: Double, distanceFromTokyo: Double) {
        self.id                = id
        self.name              = name
        self.nameKana          = nameKana
        self.region            = region
        self.latitude          = latitude
        self.longitude         = longitude
        self.distanceFromTokyo = distanceFromTokyo
    }
}

// MARK: - Seed data

extension Prefecture {
    /// DB が空のときに挿入する全 47 都道府県のシードデータ
    static let seedRows: [(id: Int, name: String, kana: String, region: Region,
                           lat: Double, lon: Double, dist: Double)] = [
        ( 1, "北海道",   "ほっかいどう",   .hokkaido, 43.0642, 141.3469,  832),
        ( 2, "青森県",   "あおもりけん",   .tohoku,   40.8244, 140.7400,  677),
        ( 3, "岩手県",   "いわてけん",     .tohoku,   39.7036, 141.1527,  570),
        ( 4, "宮城県",   "みやぎけん",     .tohoku,   38.2688, 140.8721,  346),
        ( 5, "秋田県",   "あきたけん",     .tohoku,   39.7186, 140.1023,  478),
        ( 6, "山形県",   "やまがたけん",   .tohoku,   38.2404, 140.3634,  362),
        ( 7, "福島県",   "ふくしまけん",   .tohoku,   37.7500, 140.4677,  266),
        ( 8, "茨城県",   "いばらきけん",   .kanto,    36.3418, 140.4468,  108),
        ( 9, "栃木県",   "とちぎけん",     .kanto,    36.5658, 139.8836,  109),
        (10, "群馬県",   "ぐんまけん",     .kanto,    36.3911, 139.0608,  120),
        (11, "埼玉県",   "さいたまけん",   .kanto,    35.8575, 139.6487,   40),
        (12, "千葉県",   "ちばけん",       .kanto,    35.6050, 140.1233,   40),
        (13, "東京都",   "とうきょうと",   .kanto,    35.6762, 139.6503,    0),
        (14, "神奈川県", "かながわけん",   .kanto,    35.4478, 139.6425,   35),
        (15, "新潟県",   "にいがたけん",   .chubu,    37.9161, 139.0364,  251),
        (16, "富山県",   "とやまけん",     .chubu,    36.6953, 137.2113,  260),
        (17, "石川県",   "いしかわけん",   .chubu,    36.5947, 136.6256,  321),
        (18, "福井県",   "ふくいけん",     .chubu,    36.0652, 136.2219,  349),
        (19, "山梨県",   "やまなしけん",   .chubu,    35.6639, 138.5684,  129),
        (20, "長野県",   "ながのけん",     .chubu,    36.6513, 138.1810,  210),
        (21, "岐阜県",   "ぎふけん",       .chubu,    35.3912, 136.7223,  322),
        (22, "静岡県",   "しずおかけん",   .chubu,    34.9769, 138.3831,  183),
        (23, "愛知県",   "あいちけん",     .chubu,    35.1802, 136.9066,  270),
        (24, "三重県",   "みえけん",       .kinki,    34.7303, 136.5086,  372),
        (25, "滋賀県",   "しがけん",       .kinki,    35.0045, 135.8685,  423),
        (26, "京都府",   "きょうとふ",     .kinki,    35.0211, 135.7556,  453),
        (27, "大阪府",   "おおさかふ",     .kinki,    34.6937, 135.5022,  502),
        (28, "兵庫県",   "ひょうごけん",   .kinki,    34.6913, 135.1830,  556),
        (29, "奈良県",   "ならけん",       .kinki,    34.6851, 135.8048,  461),
        (30, "和歌山県", "わかやまけん",   .kinki,    34.2260, 135.1675,  519),
        (31, "鳥取県",   "とっとりけん",   .chugoku,  35.5036, 134.2383,  624),
        (32, "島根県",   "しまねけん",     .chugoku,  35.4723, 133.0505,  754),
        (33, "岡山県",   "おかやまけん",   .chugoku,  34.6617, 133.9344,  654),
        (34, "広島県",   "ひろしまけん",   .chugoku,  34.3853, 132.4553,  723),
        (35, "山口県",   "やまぐちけん",   .chugoku,  34.1860, 131.4706,  841),
        (36, "徳島県",   "とくしまけん",   .shikoku,  34.0658, 134.5593,  637),
        (37, "香川県",   "かがわけん",     .shikoku,  34.3401, 134.0433,  670),
        (38, "愛媛県",   "えひめけん",     .shikoku,  33.8417, 132.7657,  757),
        (39, "高知県",   "こうちけん",     .shikoku,  33.5597, 133.5311,  784),
        (40, "福岡県",   "ふくおかけん",   .kyushu,   33.5904, 130.4017, 1051),
        (41, "佐賀県",   "さがけん",       .kyushu,   33.2494, 130.2988, 1099),
        (42, "長崎県",   "ながさきけん",   .kyushu,   32.7447, 129.8737, 1197),
        (43, "熊本県",   "くまもとけん",   .kyushu,   32.7898, 130.7417, 1110),
        (44, "大分県",   "おおいたけん",   .kyushu,   33.2382, 131.6126, 1015),
        (45, "宮崎県",   "みやざきけん",   .kyushu,   31.9111, 131.4239, 1109),
        (46, "鹿児島県", "かごしまけん",   .kyushu,   31.5966, 130.5571, 1201),
        (47, "沖縄県",   "おきなわけん",   .kyushu,   26.2124, 127.6809, 1555),
    ]
}
