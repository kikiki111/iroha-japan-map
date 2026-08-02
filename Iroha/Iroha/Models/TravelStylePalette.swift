//
//  TravelStylePalette.swift
//  Iroha
//
//  旅行スタイルの配色（日本の伝統色ベース）

import SwiftUI

/// 旅行スタイルの配色パレット。
///
/// - Note: `VisitMood` / `VisitTransport` と同じく `Color(hex:)` のライト固定値。
///   ダークモードでも淡色ピル（濃色文字）として描画される。
/// - Warning: rawValue は `TravelStyleRecord.paletteKey` として永続化される。変更禁止。
enum TravelStylePalette: String, CaseIterable {
    // プリセット占有（ユーザー選択肢には出さない）
    case ruri           // 瑠璃 — 一人旅
    case wakatake       // 若竹 — 家族旅行
    case kobai          // 紅梅 — 恋人旅行
    case kaki           // 柿   — 友達旅行
    case rikyunezu      // 利休鼠 — その他

    // レガシー（表示専用。旧 VisitTag の dayTrip / stay / lived）
    case legacyDayTrip
    case legacyStay
    case legacyLived

    // ユーザー選択可能な 12 色
    case beni           // 紅
    case shu            // 朱
    case kihada         // 黄檗
    case uguisu         // 鶯
    case koke           // 苔
    case sabiseiji      // 錆青磁
    case gunjou         // 群青
    case kikyou         // 桔梗
    case edomurasaki    // 江戸紫
    case suou           // 蘇芳
    case kaba           // 樺
    case tetsukon       // 鉄紺

    /// パレット選択 UI に出す色。プリセット占有色を除き、既存スタイルとの見分けを保つ。
    static let userSelectable: [TravelStylePalette] = [
        .beni, .shu, .kihada, .uguisu, .koke, .sabiseiji,
        .gunjou, .kikyou, .edomurasaki, .suou, .kaba, .tetsukon
    ]

    /// ユーザー定義スタイルの既定色（`paletteKey` が壊れていた場合のフォールバックも兼ねる）
    static let fallback: TravelStylePalette = .gunjou

    var displayName: String {
        switch self {
        case .ruri:        return "瑠璃"
        case .wakatake:    return "若竹"
        case .kobai:       return "紅梅"
        case .kaki:        return "柿"
        case .rikyunezu:   return "利休鼠"
        case .legacyDayTrip, .legacyStay, .legacyLived: return ""
        case .beni:        return "紅"
        case .shu:         return "朱"
        case .kihada:      return "黄檗"
        case .uguisu:      return "鶯"
        case .koke:        return "苔"
        case .sabiseiji:   return "錆青磁"
        case .gunjou:      return "群青"
        case .kikyou:      return "桔梗"
        case .edomurasaki: return "江戸紫"
        case .suou:        return "蘇芳"
        case .kaba:        return "樺"
        case .tetsukon:    return "鉄紺"
        }
    }

    var backgroundColor: Color { Color(hex: hexPair.bg) }
    var foregroundColor: Color { Color(hex: hexPair.fg) }

    private var hexPair: (bg: String, fg: String) {
        switch self {
        // プリセット（既存 4 色は旧 VisitTag の値をそのまま移送し、見た目を変えない）
        case .ruri:          return ("#E8F0FE", "#3468C0")
        case .wakatake:      return ("#E8F5EE", "#1D9E75")
        case .kobai:         return ("#FEE8EE", "#C0346B")
        case .kaki:          return ("#FEF3E8", "#C47A2A")
        case .rikyunezu:     return ("#EDEBE6", "#6E6A63")
        // レガシー（旧 VisitTag の値を維持）
        case .legacyDayTrip: return ("#E8F5EE", "#1D9E75")
        case .legacyStay:    return ("#EEF0FE", "#534AB7")
        case .legacyLived:   return ("#FEF3E8", "#C47A2A")
        // ユーザー選択
        case .beni:          return ("#FBE3E2", "#C13A39")
        case .shu:           return ("#FBEBDF", "#C1602C")
        case .kihada:        return ("#F7F1D6", "#97862B")
        case .uguisu:        return ("#EDF0DC", "#6E7A38")
        case .koke:          return ("#E2EDDF", "#4E7A4A")
        case .sabiseiji:     return ("#E1EDE9", "#4F8579")
        case .gunjou:        return ("#E2E4F4", "#3B4293")
        case .kikyou:        return ("#E6E2F4", "#6A4F9E")
        case .edomurasaki:   return ("#EFE4F0", "#8A4B92")
        case .suou:          return ("#F4E3E7", "#8E3B4E")
        case .kaba:          return ("#F3E7DF", "#96603F")
        case .tetsukon:      return ("#E9EBF2", "#4A5772")
        }
    }
}
