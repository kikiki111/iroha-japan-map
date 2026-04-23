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

// MARK: - Iroha theme colors

extension Color {
    // 背景・テキスト
    static let irohaWashi     = Color(hex: "#F7F4EF")
    static let irohaWashi2    = Color(hex: "#EDE8DF")
    static let irohaWashi3    = Color(hex: "#E0D8CC")
    static let irohaSumi      = Color(hex: "#1C1A2A")
    static let irohaSumi2     = Color(hex: "#4A4760")
    static let irohaSumi3     = Color(hex: "#9290A8")

    // メインカラー（紫）
    static let irohaFuji      = Color(hex: "#7F77DD")
    static let irohaFujiDk    = Color(hex: "#534AB7")
    static let irohaFujiLt    = Color(hex: "#C8C4F0")
    static let irohaFuji5     = Color(hex: "#3C3489")

    // 互換性
    static let irohaBackground = Color(hex: "#F7F4EF")
    static let irohaText       = Color(hex: "#2C2A4A")
    static let irohaFlash      = Color(hex: "#AFA9EC")

    // 訪問回数カラーマップ
    static func visitColor(count: Int, isAllVisited: Bool = false) -> Color {
        if isAllVisited { return Color(hex: "#534AB7") }
        switch count {
        case 0:    return Color(hex: "#E0D8CC")
        case 1:    return Color(hex: "#C8C4F0")
        case 2:    return Color(hex: "#9F97DD")
        case 3, 4: return Color(hex: "#7F77DD")
        default:   return Color(hex: "#534AB7")
        }
    }
}

// MARK: - Prefecture color

extension Prefecture {
    /// visitCount に応じた塗りつぶし色を返す
    func visitColor() -> Color {
        Color(hex: visitColorHex())
    }

    /// WebView へ渡す用の Hex 文字列
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
