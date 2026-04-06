//
//  PrefectureColor.swift
//  Iroha
//

import SwiftUI

// MARK: - Color(hex:) initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double(int         & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Prefecture color

extension Prefecture {
    /// visitCount に応じた塗りつぶし色を返す。
    func visitColor() -> Color {
        Color(hex: visitColorHex())
    }

    /// WebView へ渡す用の Hex 文字列（visitColor と同じ値）
    func visitColorHex() -> String {
        switch visitCount {
        case 0:    return "#DDDAD4"
        case 1:    return "#C8C4F0"
        case 2:    return "#9F97DD"
        case 3, 4: return "#7F77DD"
        default:   return "#534AB7"
        }
    }
}
