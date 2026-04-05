//
//  Visit.swift
//  Iroha
//

import Foundation
import SwiftData

@Model
final class Visit {
    var date: Date
    var memo: String?

    /// v1.1 用。現バージョンでは常に nil。
    var photoFilename: String?

    var prefecture: Prefecture?

    init(date: Date, memo: String? = nil) {
        self.date            = date
        self.memo            = memo
        self.photoFilename   = nil
    }
}
