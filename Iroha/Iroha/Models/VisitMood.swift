//
//  VisitMood.swift
//  Iroha
//
//  感情スタンプ（日本の伝統色ベース）

import SwiftUI

enum VisitMood: String, Codable, CaseIterable {
    case none      = "none"
    case tanoshi   = "tanoshi"    // 楽
    case iyashi    = "iyashi"     // 癒
    case kandou    = "kandou"     // 感
    case odoroki   = "odoroki"    // 驚
    case natsukashi = "natsukashi" // 懐
    case shizuka   = "shizuka"    // 静

    var displayName: String {
        switch self {
        case .none:      return ""
        case .tanoshi:   return "楽"
        case .iyashi:    return "癒"
        case .kandou:    return "感"
        case .odoroki:   return "驚"
        case .natsukashi: return "懐"
        case .shizuka:   return "静"
        }
    }

    var label: String {
        switch self {
        case .none:      return ""
        case .tanoshi:   return "たのしい"
        case .iyashi:    return "いやされた"
        case .kandou:    return "感動した"
        case .odoroki:   return "おどろいた"
        case .natsukashi: return "なつかしい"
        case .shizuka:   return "おだやか"
        }
    }

    /// 伝統色名
    var colorName: String {
        switch self {
        case .none:      return ""
        case .tanoshi:   return "桜"
        case .iyashi:    return "若草"
        case .kandou:    return "藤"
        case .odoroki:   return "山吹"
        case .natsukashi: return "茜"
        case .shizuka:   return "浅葱"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none:      return .clear
        case .tanoshi:   return Color(hex: "#FADCE9")
        case .iyashi:    return Color(hex: "#DDEEE0")
        case .kandou:    return Color(hex: "#E8E0F5")
        case .odoroki:   return Color(hex: "#FFF0D0")
        case .natsukashi: return Color(hex: "#FAE0D8")
        case .shizuka:   return Color(hex: "#D8EEF5")
        }
    }

    var foregroundColor: Color {
        switch self {
        case .none:      return .clear
        case .tanoshi:   return Color(hex: "#B5547A")
        case .iyashi:    return Color(hex: "#4B8F5E")
        case .kandou:    return Color(hex: "#7B6BAD")
        case .odoroki:   return Color(hex: "#B8892A")
        case .natsukashi: return Color(hex: "#B5534B")
        case .shizuka:   return Color(hex: "#3E7F95")
        }
    }

    static var selectable: [VisitMood] {
        allCases.filter { $0 != .none }
    }
}
