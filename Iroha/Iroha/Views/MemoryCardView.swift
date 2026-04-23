//
//  MemoryCardView.swift
//  Iroha
//
//  「◯年前の今日」の訪問を表示するメモリーカード

import SwiftUI
import SwiftData

/// 「◯年前の今日」の訪問を表示するメモリーカード
struct MemoryCardView: View {
    @Query(sort: \Visit.startDate) private var visits: [Visit]

    @State private var dismissed = false

    private var todayMemories: [MemoryItem] {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: Date())
        let currentYear = calendar.component(.year, from: Date())

        return visits.compactMap { visit in
            let comp = calendar.dateComponents([.month, .day, .year], from: visit.startDate)
            guard comp.month == today.month, comp.day == today.day,
                  let visitYear = comp.year, visitYear < currentYear else { return nil }
            let yearsAgo = currentYear - visitYear
            return MemoryItem(visit: visit, yearsAgo: yearsAgo)
        }
        .sorted { $0.yearsAgo < $1.yearsAgo }
    }

    var body: some View {
        if !dismissed, let memory = todayMemories.first {
            memoryCard(memory)
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
        }
    }

    private func memoryCard(_ memory: MemoryItem) -> some View {
        VStack(spacing: 0) {
            // Gradient photo area
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color.irohaFujiLt, Color(hex: "#8F87DD")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 90)
                .overlay(
                    RadialGradient(
                        colors: [.white.opacity(0.25), .clear],
                        center: UnitPoint(x: 0.7, y: 0.3),
                        startRadius: 0,
                        endRadius: 120
                    )
                )

                // "X YEARS AGO" label
                Text("\(memory.yearsAgo) YEARS AGO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.irohaSumi.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(.top, 10)
                    .padding(.leading, 12)

                // Dismiss button
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.3)) {
                            dismissed = true
                        }
                    } label: {
                        Text("\u{00D7}")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.irohaSumi.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .padding(.trailing, 12)
                }
            }

            // Body
            VStack(alignment: .leading, spacing: 3) {
                let dateString = memory.visit.startDate.formatted(
                    .dateTime.year().month(.twoDigits).day(.twoDigits)
                        .locale(Locale(identifier: "ja_JP"))
                )
                Text("\u{1F4C5} \(dateString) \u{00B7} \(memory.yearsAgo)年前の今日")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.irohaFuji)

                Text(memory.visit.prefectureName)
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(.irohaSumi)

                if !memory.visit.note.isEmpty {
                    Text(memory.visit.note)
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi2)
                        .lineSpacing(4)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white)
            .overlay(
                Rectangle()
                    .stroke(Color.irohaWashi3, lineWidth: 0.5)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: Color.irohaFuji5.opacity(0.18), radius: 7, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

// MARK: - MemoryItem

private struct MemoryItem {
    let visit: Visit
    let yearsAgo: Int
}
