//
//  MemoryCardView.swift
//  Iroha
//
//  「◯年前の今日」の旅行を表示するメモリーカード

import SwiftUI
import SwiftData

struct MemoryCardView: View {
    var onTap: ((Visit) -> Void)?

    @Query(sort: \Visit.startDate) private var visits: [Visit]
    @AppStorage("show_memory_card") private var showMemoryCard = true

    @State private var dismissed = false
    @State private var currentIndex = 0

    private var todayMemories: [MemoryItem] {
        let calendar = Calendar.current
        let today = calendar.dateComponents([.month, .day], from: Date())
        let currentYear = calendar.component(.year, from: Date())

        // 居住は除外。引っ越し日が今日の月日と一致しただけで
        // 「N 年前の今日の旅」として旅行と同列に出てしまうため。
        return visits.filter { !$0.isResidence }.compactMap { visit in
            // 日付が曖昧な記録も除外。代表日 (月末 / 12/31) は実際の訪問日ではないため、
            // 「今日と同じ月日」の判定に紛れ込ませない。
            guard !visit.isDateAmbiguous else { return nil }
            let comp = calendar.dateComponents([.month, .day, .year], from: visit.startDate)
            guard comp.month == today.month, comp.day == today.day,
                  let visitYear = comp.year, visitYear < currentYear else { return nil }
            let yearsAgo = currentYear - visitYear
            return MemoryItem(visit: visit, yearsAgo: yearsAgo)
        }
        .sorted { $0.yearsAgo < $1.yearsAgo }
    }

    var body: some View {
        let memories = todayMemories
        if showMemoryCard, !dismissed, !memories.isEmpty {
            VStack(spacing: 0) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(memories.enumerated()), id: \.element.visit.id) { index, memory in
                        memoryCard(memory)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: memories.count > 1 ? .automatic : .never))
                .frame(height: 195)

                if memories.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<memories.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.irohaFuji : Color.irohaSumi3.opacity(0.25))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 2)
                }
            }
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
        }
    }

    private func memoryCard(_ memory: MemoryItem) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let photoData = memory.visit.sortedPhotoThumbnails.first,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.black.opacity(0.35), .clear, .black.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    LinearGradient(
                        colors: [Color.irohaFujiLt, Color(hex: "#8F87DD")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .overlay(
                        RadialGradient(
                            colors: [.white.opacity(0.25), .clear],
                            center: UnitPoint(x: 0.7, y: 0.3),
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                }

                Text("\(memory.yearsAgo)年前")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.irohaSumi.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(.top, 10)
                    .padding(.leading, 12)

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

            VStack(alignment: .leading, spacing: 3) {
                let dateString = VisitDateFormat.compactText(
                    memory.visit.startDate,
                    accuracy: memory.visit.effectiveDateAccuracy
                )
                Text("\(dateString) \u{00B7} \(memory.yearsAgo)年前の今日")
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
            .background(Color.irohaCard)
            .overlay(
                Rectangle()
                    .stroke(Color.irohaWashi3, lineWidth: 0.5)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: Color.irohaFuji5.opacity(0.18), radius: 7, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 13))
        .onTapGesture { onTap?(memory.visit) }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

private struct MemoryItem {
    let visit: Visit
    let yearsAgo: Int
}
