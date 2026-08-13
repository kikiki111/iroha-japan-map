//
//  VisitTagBadge.swift
//  Iroha
//
//  旅行スタイルのバッジ表示

import SwiftUI

/// 旅行スタイルをカラーバッジとして表示する。
///
/// `style == nil`（未選択・削除済み・他端末から未同期）のときは何も描画しない。
/// 呼び出し側で未選択かどうかを判定する必要はない。
struct VisitTagBadge: View {
    let style: TravelStyle?

    var body: some View {
        if let style {
            Text(style.name)
                .font(.system(size: Metrics.fontSize, weight: .medium))
                .foregroundColor(style.foregroundColor)
                .padding(.horizontal, Metrics.hPadding)
                .padding(.vertical, Metrics.vPadding)
                .background(style.backgroundColor)
                .clipShape(Capsule())
        }
    }

    private enum Metrics {
        static let fontSize: CGFloat = 12
        static let hPadding: CGFloat = 8
        static let vPadding: CGFloat = 2
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
            VisitTagBadge(style: TravelStylePreset.solo.style)
            VisitTagBadge(style: TravelStylePreset.family.style)
            VisitTagBadge(style: TravelStylePreset.couple.style)
        }
        HStack(spacing: 8) {
            VisitTagBadge(style: TravelStylePreset.friends.style)
            VisitTagBadge(style: TravelStylePreset.other.style)
        }
    }
    .padding()
}
