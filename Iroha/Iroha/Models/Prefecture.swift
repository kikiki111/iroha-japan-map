//
//  Prefecture.swift
//  Iroha
//

import Foundation
import SwiftData

@Model
final class Prefecture {
    /// 都道府県コード（01〜47）
    var id: Int
    var name: String
    var region: Region
    /// 都道府県庁所在地の緯度（地図ラベル配置などに使用）
    var latitude: Double

    @Relationship(deleteRule: .cascade)
    var visits: [Visit] = []

    var isVisited: Bool  { !visits.isEmpty }
    var visitCount: Int  { visits.count }

    init(id: Int, name: String, region: Region, latitude: Double) {
        self.id       = id
        self.name     = name
        self.region   = region
        self.latitude = latitude
    }
}
