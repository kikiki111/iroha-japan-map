//
//  VisitTag.swift
//  Iroha
//

import SwiftUI

/// 訪問タグ（日帰り / 宿泊 / 居住）
enum VisitTag: String, Codable, CaseIterable {
    case none     = "none"
    case dayTrip  = "dayTrip"
    case stay     = "stay"
    case lived    = "lived"

    var displayName: String {
        switch self {
        case .none:    return ""
        case .dayTrip: return "日帰り"
        case .stay:    return "宿泊"
        case .lived:   return "居住"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none:    return .clear
        case .dayTrip: return Color(hex: "#E8F5EE")
        case .stay:    return Color(hex: "#EEF0FE")
        case .lived:   return Color(hex: "#FEF3E8")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .none:    return .clear
        case .dayTrip: return Color(hex: "#1D9E75")
        case .stay:    return Color(hex: "#534AB7")
        case .lived:   return Color(hex: "#C47A2A")
        }
    }
}
