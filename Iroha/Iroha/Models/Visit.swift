//
//  Visit.swift
//  Iroha
//

import Foundation
import SwiftData

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
