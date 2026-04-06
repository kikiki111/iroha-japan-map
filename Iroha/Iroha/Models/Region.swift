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
        case .hokkaido: return Color(hex: "#7F77DD")
        case .tohoku:   return Color(hex: "#8F87DD")
        case .kanto:    return Color(hex: "#9F97DD")
        case .chubu:    return Color(hex: "#AFA9EC")
        case .kinki:    return Color(hex: "#BFBBF0")
        case .chugoku:  return Color(hex: "#CFCDF4")
        case .shikoku:  return Color(hex: "#DFDDF8")
        case .kyushu:   return Color(hex: "#EFEDFB")
        }
    }
}
