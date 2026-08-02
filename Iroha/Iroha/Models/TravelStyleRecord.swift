//
//  TravelStyleRecord.swift
//  Iroha
//

import Foundation
import SwiftData

/// ユーザー操作で生まれる旅行スタイルの永続レコード。
///
/// 2 種類の行が同居する:
/// 1. **カスタム行** (`presetKey.isEmpty == true`) — ユーザーが追加したスタイル
/// 2. **プリセット非表示行** (`presetKey.isEmpty == false`) —
///    ユーザーがプリセットを非表示にしたときだけ遅延生成される 1 行
///
/// - Important: プリセットを起動時に一括 seed してはならない。
///   `Prefecture` を SwiftData から外した理由（複数端末での seed 重複）と同じ問題が
///   そのまま再発するため。行はユーザー操作のときだけ作る。
/// - Note: CloudKit 制約に従い全プロパティに default 値を持たせ、`@Attribute(.unique)` は使わない。
///   同一 `presetKey` の非表示行が複数端末で重複しても、`isHidden` を OR で畳むため無害。
@Model
final class TravelStyleRecord {
    var id: UUID = UUID()
    /// 空文字ならカスタム行。非空なら `TravelStylePreset.rawValue` の非表示行
    var presetKey: String = ""
    var name: String = ""
    var iconName: String = ""
    /// `TravelStylePalette.rawValue`
    var paletteKey: String = ""
    var isHidden: Bool = false
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    init(id: UUID = UUID(),
         presetKey: String = "",
         name: String = "",
         iconName: String = "",
         paletteKey: String = "",
         isHidden: Bool = false,
         sortOrder: Int = 0,
         createdAt: Date = Date()) {
        self.id         = id
        self.presetKey  = presetKey
        self.name       = name
        self.iconName   = iconName
        self.paletteKey = paletteKey
        self.isHidden   = isHidden
        self.sortOrder  = sortOrder
        self.createdAt  = createdAt
    }

    var isPresetOverride: Bool { !presetKey.isEmpty }

    /// `Visit.tag` に格納される ID
    var styleID: String {
        isPresetOverride ? presetKey : TravelStyleID.custom(id)
    }

    var palette: TravelStylePalette {
        TravelStylePalette(rawValue: paletteKey) ?? TravelStylePalette.fallback
    }

    /// カスタム行を `TravelStyle` に投影する。非表示行では nil を返す。
    var customStyle: TravelStyle? {
        guard !isPresetOverride else { return nil }
        return TravelStyle(
            id: styleID,
            name: name,
            iconName: TravelStyleIcon.resolved(iconName),
            palette: palette,
            isPreset: false,
            isLegacy: false
        )
    }
}
