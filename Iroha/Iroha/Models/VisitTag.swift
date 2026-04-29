//
//  VisitTag.swift
//  Iroha
//

import SwiftUI

/// 旅行スタイル
enum VisitTag: String, Codable, CaseIterable {
    case none     = "none"
    case solo     = "solo"
    case family   = "family"
    case couple   = "couple"
    case friends  = "friends"

    // Legacy (hidden from picker, kept for data compatibility)
    case dayTrip  = "dayTrip"
    case stay     = "stay"
    case lived    = "lived"

    static var selectableCases: [VisitTag] {
        [.solo, .family, .couple, .friends]
    }

    var displayName: String {
        switch self {
        case .none:    return ""
        case .solo:    return "一人旅"
        case .family:  return "家族旅行"
        case .couple:  return "恋人旅行"
        case .friends: return "友達旅行"
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
        default:       return ""
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none:    return .clear
        case .solo:    return Color(hex: "#E8F0FE")
        case .family:  return Color(hex: "#E8F5EE")
        case .couple:  return Color(hex: "#FEE8EE")
        case .friends: return Color(hex: "#FEF3E8")
        case .dayTrip: return Color(hex: "#E8F5EE")
        case .stay:    return Color(hex: "#EEF0FE")
        case .lived:   return Color(hex: "#FEF3E8")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .none:    return .clear
        case .solo:    return Color(hex: "#3468C0")
        case .family:  return Color(hex: "#1D9E75")
        case .couple:  return Color(hex: "#C0346B")
        case .friends: return Color(hex: "#C47A2A")
        case .dayTrip: return Color(hex: "#1D9E75")
        case .stay:    return Color(hex: "#534AB7")
        case .lived:   return Color(hex: "#C47A2A")
        }
    }
}
