//
//  Prefecture.swift
//  Iroha
//

import Foundation
import SwiftData

@Model
final class Prefecture {
    /// JIS 都道府県コード（1〜47）
    var id: Int
    var name: String
    var region: Region
    /// 重心緯度（ラベル配置用）
    var latitude: Double

    @Relationship(deleteRule: .cascade)
    var visits: [Visit] = []

    /// 1 回以上訪問済みかどうか
    var isVisited: Bool { !visits.isEmpty }
    /// 訪問回数
    var visitCount: Int { visits.count }

    init(id: Int, name: String, region: Region, latitude: Double) {
        self.id = id
        self.name = name
        self.region = region
        self.latitude = latitude
    }
}
