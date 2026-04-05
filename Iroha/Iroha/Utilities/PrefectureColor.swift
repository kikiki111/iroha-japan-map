//
//  PrefectureColor.swift
//  Iroha
//

import SwiftUI

// MARK: - Color(hex:) initializer

extension Color {
    /// `#RRGGBB` 形式の16進数文字列からカラーを生成する。
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >>  8) & 0xFF) / 255.0
        let b = Double( int        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Prefecture visit color

extension Prefecture {
    /// 訪問回数に応じた塗り色を返す。
    func visitColor() -> Color {
        switch visitCount {
        case 0:       return Color(hex: "#DDDAD4")
        case 1:       return Color(hex: "#C8C4F0")
        case 2:       return Color(hex: "#9F97DD")
        case 3, 4:    return Color(hex: "#7F77DD")
        default:      return Color(hex: "#534AB7")
        }
    }
}
