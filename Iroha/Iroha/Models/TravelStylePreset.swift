//
//  TravelStylePreset.swift
//  Iroha
//
//  アプリが標準で持つ旅行スタイル

import Foundation

/// プリセット旅行スタイル。
///
/// `Prefecture` と同じく **SwiftData には一切 seed しない**。
/// 全端末が同一の静的テーブルを持つため、CloudKit 上での seed 重複が原理的に起きない。
/// ユーザーは非表示にできるだけで、名前・色・アイコンは変更できない。
///
/// - Warning: rawValue は `Visit.styleID` に永続化される。既存 key の変更・再利用は禁止。
enum TravelStylePreset: String, CaseIterable {
    // 既存 4 種（rawValue を変えないこと）
    case solo    = "solo"
    case family  = "family"
    case couple  = "couple"
    case friends = "friends"
    // 4 種のどれにも当てはまらない旅の受け皿
    case other   = "other"
    // レガシー: 旧 VisitTag から引き継ぐ。選択肢には出さないが表示は維持する
    case dayTrip = "dayTrip"
    case stay    = "stay"
    case lived   = "lived"

    var isLegacy: Bool {
        switch self {
        case .dayTrip, .stay, .lived: return true
        default:                      return false
        }
    }

    /// ピッカー・設定画面に出す順序付きリスト（レガシー除外）
    static var selectable: [TravelStylePreset] {
        allCases.filter { !$0.isLegacy }
    }

    /// `Badge.threeStyles` でカウントから除外する ID
    static let legacyIDs: Set<String> = Set(allCases.filter(\.isLegacy).map(\.rawValue))

    var displayName: String {
        switch self {
        case .solo:    return "一人旅"
        case .family:  return "家族旅行"
        case .couple:  return "恋人旅行"
        case .friends: return "友達旅行"
        case .other:   return "その他"
        case .dayTrip: return "日帰り"
        case .stay:    return "宿泊"
        case .lived:   return "居住"
        }
    }

    var iconName: String {
        switch self {
        case .solo:    return "person"
        case .family:  return "figure.2.and.child.holdinghands"
        case .couple:  return "heart"
        case .friends: return "person.3"
        case .other:   return "ellipsis.circle"
        case .dayTrip, .stay, .lived: return ""
        }
    }

    var palette: TravelStylePalette {
        switch self {
        case .solo:    return .ruri
        case .family:  return .wakatake
        case .couple:  return .kobai
        case .friends: return .kaki
        case .other:   return .rikyunezu
        case .dayTrip: return .legacyDayTrip
        case .stay:    return .legacyStay
        case .lived:   return .legacyLived
        }
    }

    var style: TravelStyle {
        TravelStyle(
            id: rawValue,
            name: displayName,
            iconName: TravelStyleIcon.resolved(iconName),
            palette: palette,
            isPreset: true,
            isLegacy: isLegacy
        )
    }
}
