//
//  VisitTagBadge.swift
//  Iroha
//
//  訪問タグ（日帰り/宿泊/居住）のバッジ表示

import SwiftUI

/// 訪問タグをカラーバッジとして表示
struct VisitTagBadge: View {
    let tag: VisitTag

    var body: some View {
        if tag != .none {
            Text(tag.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(tag.foregroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(tag.backgroundColor)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 8) {
        VisitTagBadge(tag: .dayTrip)
        VisitTagBadge(tag: .stay)
        VisitTagBadge(tag: .lived)
    }
    .padding()
}
