//
//  Region.swift
//  Iroha
//

import SwiftUI

/// 日本の地方区分（全 8 地方）。SwiftData で永続化するため String の RawRepresentable。
enum Region: String, Codable, CaseIterable {
    case hokkaido
    case tohoku
    case kanto
    case chubu
    case kinki
    case chugoku
    case shikoku
    case kyushu

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

    var color: Color {
        switch self {
        case .hokkaido: return Color(hex: "#5B9BD5")  // ice blue
        case .tohoku:   return Color(hex: "#70AD47")  // forest green
        case .kanto:    return Color(hex: "#FF7043")  // tokyo orange
        case .chubu:    return Color(hex: "#8D6E63")  // mountain brown
        case .kinki:    return Color(hex: "#FFA726")  // kyo amber
        case .chugoku:  return Color(hex: "#26A69A")  // sea teal
        case .shikoku:  return Color(hex: "#9CCC65")  // nature green
        case .kyushu:   return Color(hex: "#EF5350")  // volcano red
        }
    }
}
