//
//  Visit.swift
//  Iroha
//

import Foundation
import SwiftData

/// 都道府県への訪問を表す SwiftData モデル
@Model
final class Visit {
    var prefectureName: String
    /// 旧 `date` 属性からのライトウェイトマイグレーション対応
    @Attribute(originalName: "date")
    var startDate: Date
    /// nil = 日帰り（startDate と同日）
    var endDate: Date?
    var note: String
    /// v1.1 用。現バージョンでは常に nil。
    var photoFilename: String?

    /// 訪問先都道府県への逆参照。Prefecture.visits との双方向 Relationship を構成する。
    var prefecture: Prefecture?

    init(prefectureName: String, startDate: Date, endDate: Date? = nil, note: String = "") {
        self.prefectureName = prefectureName
        self.startDate      = startDate
        self.endDate        = endDate
        self.note           = note
        self.photoFilename  = nil
    }

    /// 帰着日（nil の場合は startDate を返す）
    var effectiveEndDate: Date { endDate ?? startDate }
}
