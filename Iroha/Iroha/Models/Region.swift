//
//  Region.swift
//  Iroha
//

import SwiftUI

enum Region: String, Codable, CaseIterable {
    case hokkaido = "hokkaido"
    case tohoku   = "tohoku"
    case kanto    = "kanto"
    case chubu    = "chubu"
    case kinki    = "kinki"
    case chugoku  = "chugoku"
    case shikoku  = "shikoku"
    case kyushu   = "kyushu"

    var localizedName: String {
        switch self {
        case .hokkaido: return "北海道"
        case .tohoku:   return "東北"
        case .kanto:    return "関東"
        case .chubu:    return "中部"
        case .kinki:    return "近畿"
        case .chugoku:  return "中国"
        case .shikoku:  return "四国"
        case .kyushu:   return "九州"
        }
    }

    /// 地方ごとの代表色
    var color: Color {
        switch self {
        case .hokkaido: return Color(hex: "#5B9BD5")
        case .tohoku:   return Color(hex: "#70AD47")
        case .kanto:    return Color(hex: "#FF7043")
        case .chubu:    return Color(hex: "#8D6E63")
        case .kinki:    return Color(hex: "#FFA726")
        case .chugoku:  return Color(hex: "#26A69A")
        case .shikoku:  return Color(hex: "#9CCC65")
        case .kyushu:   return Color(hex: "#EF5350")
        }
    }
}
