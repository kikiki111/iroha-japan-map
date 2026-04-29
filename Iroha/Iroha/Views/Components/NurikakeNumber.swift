//
//  NurikakeNumber.swift
//  Iroha
//
//  下から紫（fujiDk）で塗り上げる塗りかけ数字コンポーネント

import SwiftUI

/// 「塗りかけ」デザインの数字表示
/// 下から色付きで塗り上げる
struct NurikakeNumber: View {
    let value: Int
    var fontSize: CGFloat = 36
    var topColor: Color = .irohaFujiDk
    var bottomColor: Color = .irohaWashi3
    /// 塗りつぶし率（0.0〜1.0）。nil の場合はデフォルト48%
    var ratio: Double? = nil

    private var fillRatio: CGFloat {
        if let ratio { return CGFloat(min(max(ratio, 0), 1)) }
        return 0.48
    }

    private var glyphMetrics: (topInset: CGFloat, glyphHeight: CGFloat) {
        let uiFont = UIFont.systemFont(ofSize: fontSize, weight: .light)
        let capHeight = uiFont.capHeight
        let descent = uiFont.descender
        let lineHeight = uiFont.lineHeight
        let topInset = lineHeight - capHeight + descent
        return (topInset, capHeight)
    }

    var body: some View {
        let metrics = glyphMetrics
        let maskHeight = metrics.glyphHeight * fillRatio
        let bottomOffset = metrics.topInset

        ZStack(alignment: .topLeading) {
            Text(verbatim: "\(value)")
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(bottomColor)

            if fillRatio > 0 {
                Text(verbatim: "\(value)")
                    .font(.system(size: fontSize, weight: .light, design: .serif))
                    .foregroundColor(topColor)
                    .mask(
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .frame(height: maskHeight)
                                .padding(.bottom, bottomOffset)
                        }
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(value)"))
    }
}

/// 塗りかけテキスト（年号など任意のテキスト）
struct NurikakeText: View {
    let text: String
    var fontSize: CGFloat = 28
    var topColor: Color = .irohaFujiDk
    var bottomColor: Color = Color(hex: "#A09EB6")
    var fillFromTop: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(verbatim: text)
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(bottomColor)

            Text(verbatim: text)
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(topColor)
                .mask(
                    VStack(spacing: 0) {
                        if !fillFromTop { Spacer(minLength: 0) }
                        Rectangle()
                            .frame(height: fontSize * 0.48)
                        if fillFromTop { Spacer(minLength: 0) }
                    }
                    .frame(height: fontSize)
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: text))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        NurikakeNumber(value: 23, fontSize: 44)
        NurikakeNumber(value: 47, fontSize: 36)
        NurikakeText(text: "2025", fontSize: 30)
    }
    .padding()
    .background(Color.irohaWashi)
}
