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
    var date: Date
    var note: String

    init(prefectureName: String, date: Date, note: String = "") {
        self.prefectureName = prefectureName
        self.date = date
        self.note = note
    }
}
