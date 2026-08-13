//
//  TravelStyle.swift
//  Iroha
//
//  旅行スタイルの統一表現

import SwiftUI

/// `Visit.styleID` に格納される ID の規約
enum TravelStyleID {
    /// 旧 `VisitTag.none` の rawValue。既存レコードに実在するため未選択として扱い続ける。
    ///
    /// - Warning: `TravelStylePreset` に rawValue `"none"` のケースを追加してはならない。
    static let noneSentinel = "none"

    /// ユーザー定義スタイルの ID 接頭辞。プリセットの rawValue と衝突させないために付ける。
    static let customPrefix = "u:"

    static func custom(_ uuid: UUID) -> String { customPrefix + uuid.uuidString }

    static func isCustom(_ id: String) -> Bool { id.hasPrefix(customPrefix) }
}

/// UI が扱う旅行スタイルの統一表現。
///
/// プリセット (`TravelStylePreset`) とユーザー定義 (`TravelStyleRecord`) の
/// どちらからも生成され、View 側は出自を意識しない。
///
/// - Note: protocol ではなく struct にしている。`ForEach` / `Set` / `Menu` の selection に
///   載せるため `Identifiable + Hashable` が要るが、existential では型消去で詰まるため。
struct TravelStyle: Identifiable {
    /// `Visit.styleID` に格納される ID。プリセットは rawValue、カスタムは `"u:UUID"`
    let id: String
    let name: String
    let iconName: String
    let palette: TravelStylePalette
    let isPreset: Bool
    /// 旧 dayTrip / stay / lived。表示はできるが選択肢には出さない
    let isLegacy: Bool

    var backgroundColor: Color { palette.backgroundColor }
    var foregroundColor: Color { palette.foregroundColor }
}

extension TravelStyle: Hashable {
    static func == (lhs: TravelStyle, rhs: TravelStyle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// 旅行スタイルの入力上限
enum TravelStyleLimit {
    static let maxNameLength = 12
    static let maxCustomCount = 20
}
