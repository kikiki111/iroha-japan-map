//
//  BadgeStampView.swift
//  Iroha
//

import SwiftUI

struct BadgeStampView: View {
    let badge: Badge
    let earned: Bool
    var locked: Bool = false

    private let size: CGFloat = 52

    var body: some View {
        if earned {
            earnedStamp
        } else if locked {
            lockedStamp
        } else {
            unearnedStamp
        }
    }

    private var color: Color { badge.stampColor }

    private var earnedStamp: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.1))
            Circle()
                .strokeBorder(color, lineWidth: 2)

            Text(badge.stampCharacter)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(badge.stampRotation))
    }

    private var lockedStamp: some View {
        Circle()
            .strokeBorder(Color.irohaSumi3.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.irohaSumi3.opacity(0.2))
            }
    }

    private var unearnedStamp: some View {
        Circle()
            .strokeBorder(Color.irohaSumi3.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .frame(width: size, height: size)
            .overlay {
                Text("？")
                    .font(.system(size: 18, design: .serif))
                    .foregroundColor(.irohaSumi3.opacity(0.3))
            }
    }
}
