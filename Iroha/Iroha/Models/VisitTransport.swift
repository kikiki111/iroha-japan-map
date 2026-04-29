//
//  VisitTransport.swift
//  Iroha
//

import SwiftUI

enum VisitTransport: String, Codable, CaseIterable {
    case none        = "none"
    case car         = "car"
    case train       = "train"
    case shinkansen  = "shinkansen"
    case airplane    = "airplane"
    case bus         = "bus"
    case ship        = "ship"
    case bicycle     = "bicycle"
    case walking     = "walking"

    var displayName: String {
        switch self {
        case .none:        return ""
        case .car:         return "車"
        case .train:       return "電車"
        case .shinkansen:  return "新幹線"
        case .airplane:    return "飛行機"
        case .bus:         return "バス"
        case .ship:        return "船"
        case .bicycle:     return "自転車"
        case .walking:     return "徒歩"
        }
    }

    var iconName: String {
        switch self {
        case .none:        return ""
        case .car:         return "car.fill"
        case .train:       return "tram.fill"
        case .shinkansen:  return "train.side.front.car"
        case .airplane:    return "airplane"
        case .bus:         return "bus.fill"
        case .ship:        return "ferry.fill"
        case .bicycle:     return "bicycle"
        case .walking:     return "figure.walk"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .none:        return .clear
        case .car:         return Color(hex: "#B5534B") // 茜
        case .train:       return Color(hex: "#3E7F95") // 浅葱
        case .shinkansen:  return Color(hex: "#2E6DB4") // 縹
        case .airplane:    return Color(hex: "#7B6BAD") // 藤
        case .bus:         return Color(hex: "#B8892A") // 山吹
        case .ship:        return Color(hex: "#4B8F5E") // 若草
        case .bicycle:     return Color(hex: "#C47A2A") // 柿色
        case .walking:     return Color(hex: "#8B6B4A") // 渋紙
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none:        return .clear
        case .car:         return Color(hex: "#FAE0D8")
        case .train:       return Color(hex: "#D8EEF5")
        case .shinkansen:  return Color(hex: "#D8E4F5")
        case .airplane:    return Color(hex: "#E8E0F5")
        case .bus:         return Color(hex: "#FFF0D0")
        case .ship:        return Color(hex: "#DDEEE0")
        case .bicycle:     return Color(hex: "#FEF3E8")
        case .walking:     return Color(hex: "#F0E8DD")
        }
    }

    static var selectable: [VisitTransport] {
        allCases.filter { $0 != .none }
    }
}
