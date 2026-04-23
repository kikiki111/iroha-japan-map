//
//  NurikakeNumber.swift
//  Iroha
//
//  上半分が紫（fujiDk）・下半分がグレー（washi3）の塗りかけ数字コンポーネント

import SwiftUI

/// 「塗りかけ」デザインの数字表示
/// 上半分が色付き、下半分がグレーで表示される
struct NurikakeNumber: View {
    let value: Int
    var fontSize: CGFloat = 36
    var topColor: Color = .irohaFujiDk
    var bottomColor: Color = .irohaWashi3

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 下層：グレー（全体）
            Text(verbatim: "\(value)")
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(bottomColor)

            // 上層：紫（上48%だけ表示）
            Text(verbatim: "\(value)")
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(topColor)
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: fontSize * 0.48)
                        Spacer(minLength: 0)
                    }
                    .frame(height: fontSize)
                )
        }
    }
}

/// 塗りかけテキスト（年号など任意のテキスト）
struct NurikakeText: View {
    let text: String
    var fontSize: CGFloat = 28
    var topColor: Color = .irohaFujiDk
    var bottomColor: Color = .irohaWashi3

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(bottomColor)

            Text(text)
                .font(.system(size: fontSize, weight: .light, design: .serif))
                .foregroundColor(topColor)
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: fontSize * 0.48)
                        Spacer(minLength: 0)
                    }
                    .frame(height: fontSize)
                )
        }
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
