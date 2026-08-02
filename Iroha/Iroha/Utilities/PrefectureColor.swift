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

// MARK: - Adaptive color helper

extension Color {
    /// ライト/ダークで異なる色を返すヘルパー
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}

// MARK: - Iroha theme colors

extension Color {
    // 背景・テキスト（ダークモード対応）
    static let irohaWashi     = Color.adaptive(light: "#F7F4EF", dark: "#1A1826")
    static let irohaWashi2    = Color.adaptive(light: "#EDE8DF", dark: "#242236")
    static let irohaWashi3    = Color.adaptive(light: "#E0D8CC", dark: "#3A3750")
    static let irohaSumi      = Color.adaptive(light: "#1C1A2A", dark: "#F0EDE8")
    static let irohaSumi2     = Color.adaptive(light: "#4A4760", dark: "#C0BDD0")
    static let irohaSumi3     = Color.adaptive(light: "#9290A8", dark: "#8886A0")

    // メインカラー（紫）
    static let irohaFuji      = Color(hex: "#7F77DD")
    static let irohaFujiDk    = Color.adaptive(light: "#534AB7", dark: "#9F97EE")
    static let irohaFujiLt    = Color.adaptive(light: "#C8C4F0", dark: "#4A4280")
    static let irohaFuji5     = Color(hex: "#3C3489")

    // 居住カラー（金茶）
    //
    // 旅行の紫 (irohaFuji 系) と同じ役割・同じ濃度で、色相だけを変えたペア。
    // 書式 (サイズ・ウェイト) を旅行と揃えたうえで色だけで区別するため、
    // `irohaSumikaDk` は `irohaFujiDk` (#534AB7) と同程度の視認性に合わせてある。
    static let irohaSumika    = Color(hex: "#C9A227")
    static let irohaSumikaDk  = Color.adaptive(light: "#8A6D10", dark: "#D9BC5E")
    static let irohaSumikaLt  = Color.adaptive(light: "#F5EEDC", dark: "#413920")

    /// 地図の居住県塗り色（WebView へ渡す Hex）。ライト/ダーク非依存の固定値。
    /// 未訪問グレー `#DDDAD4` と同程度の明度で、旅行 1 回の薄紫 `#C8C4F0` より弱い。
    static let residenceHex   = "#E8D9A8"

    // 互換性
    static let irohaBackground = irohaWashi
    static let irohaText       = irohaSumi
    static let irohaFlash      = Color(hex: "#AFA9EC")

    // カード背景（設定画面などの .white 代替）
    static let irohaCard      = Color.adaptive(light: "#FFFFFF", dark: "#242236")

    // 訪問回数カラーマップ
    static func visitColor(count: Int, isAllVisited: Bool = false) -> Color {
        if isAllVisited { return Color(hex: "#534AB7") }
        switch count {
        case 0:    return irohaWashi3
        case 1:    return Color(hex: "#C8C4F0")
        case 2:    return Color(hex: "#9F97DD")
        case 3, 4: return Color(hex: "#7F77DD")
        default:   return Color(hex: "#534AB7")
        }
    }
}

// 都道府県の色判定は `VisitStats` の extension に移植済み (Utilities/VisitStats.swift)。
// Prefecture は static struct となり、訪問状態を保持しないため、
// `stats.colorHex(for: prefecture)` / `stats.color(for: prefecture)` を使用すること。
