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
    /// 訪問タグ（日帰り / 宿泊 / 居住）
    var tag: VisitTag?
    /// 写真ファイル名（Documents/Photos/ に保存）
    var photoFilename: String?
    /// サムネイル画像データ（リスト表示用、300px JPEG）
    var photoThumbnail: Data?

    /// 訪問先都道府県への逆参照
    var prefecture: Prefecture?

    init(prefectureName: String, startDate: Date, endDate: Date? = nil,
         note: String = "", tag: VisitTag = .none) {
        self.prefectureName = prefectureName
        self.startDate      = startDate
        self.endDate        = endDate
        self.note           = note
        self.tag            = tag
        self.photoFilename  = nil
    }

    /// タグの安全なアクセス（nil → .none）
    var effectiveTag: VisitTag { tag ?? .none }

    /// 帰着日（nil の場合は startDate を返す）
    var effectiveEndDate: Date { endDate ?? startDate }
}
