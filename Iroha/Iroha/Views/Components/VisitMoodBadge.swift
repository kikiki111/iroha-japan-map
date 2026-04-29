//
//  VisitMoodBadge.swift
//  Iroha
//
//  感情スタンプの判子風バッジ表示

import SwiftUI

struct VisitMoodBadge: View {
    let mood: VisitMood

    var body: some View {
        if mood != .none {
            Text(mood.displayName)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundColor(mood.foregroundColor)
                .frame(width: 22, height: 22)
                .background(mood.backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(mood.foregroundColor.opacity(0.3), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 8) {
        ForEach(VisitMood.selectable, id: \.rawValue) { mood in
            VStack(spacing: 4) {
                VisitMoodBadge(mood: mood)
                Text(mood.label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    .padding()
}
