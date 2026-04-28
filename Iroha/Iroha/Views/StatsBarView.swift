//
//  StatsBarView.swift
//  Iroha
//
//  地図下部の統計エリア（塗りかけデザイン）

import SwiftUI
import SwiftData

/// 地図の下に表示する統計バー
struct IrohaStatsBar: View {
    let prefectures: [Prefecture]
    var mapViewModel: MapViewModel

    private var visitedCount: Int { mapViewModel.visitedPrefectureCount(prefectures: prefectures) }
    private var totalVisits: Int { mapViewModel.totalVisitCount(prefectures: prefectures) }
    private var ratio: Double { mapViewModel.achievementRatio(prefectures: prefectures) }

    @State private var selectedRegion: MapViewModel.RegionProgress?

    var body: some View {
        VStack(spacing: 0) {
            // Main stats row
            HStack(alignment: .bottom, spacing: 5) {
                NurikakeNumber(value: visitedCount, fontSize: 36)
                Text("/ 47")
                    .font(.system(size: 14))
                    .foregroundColor(.irohaSumi3)
                    .padding(.bottom, 5)
                Spacer()
                Text(String(format: "%.0f%%", ratio * 100))
                    .font(.system(size: 13))
                    .foregroundColor(.irohaSumi3)
                    .padding(.bottom, 5)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.irohaWashi3)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.irohaFujiLt, .irohaFuji, .irohaFujiDk],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(ratio)), height: 5)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 16)
            .padding(.top, 5)

            // 8-region dots
            HStack(spacing: 6) {
                ForEach(mapViewModel.regionProgressList(prefectures: prefectures).reversed()) { progress in
                    regionDot(progress: progress)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedRegion?.id == progress.id {
                                    selectedRegion = nil
                                } else {
                                    selectedRegion = progress
                                }
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 4)

            // Region detail popup
            if let selected = selectedRegion {
                HStack(spacing: 4) {
                    Text(selected.region.localizedName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.irohaSumi)
                    Text("\(selected.visited)/\(selected.total)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.irohaSumi3)
                        .monospacedDigit()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.irohaCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.irohaWashi3, lineWidth: 0.5))
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                .padding(.bottom, 4)
            } else {
                Spacer().frame(height: 8)
            }
        }
    }

    private func regionDot(progress: MapViewModel.RegionProgress) -> some View {
        let dotSize: CGFloat = 22
        let isFull = progress.visited == progress.total && progress.total > 0
        let isEmpty = progress.visited == 0
        let isSelected = selectedRegion?.id == progress.id
        let fillHeight = dotSize * CGFloat(progress.ratio)

        return Circle()
            .fill(isFull ? Color.irohaFujiDk : Color.irohaWashi3)
            .frame(width: dotSize, height: dotSize)
            .overlay(
                !isFull && !isEmpty ?
                Circle()
                    .fill(Color.irohaFuji)
                    .mask(
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            Rectangle()
                                .frame(height: fillHeight)
                        }
                        .frame(height: dotSize)
                    )
                : nil
            )
            .overlay(
                isSelected ?
                Circle().stroke(Color.irohaFujiDk, lineWidth: 2)
                : nil
            )
            .animation(.easeInOut(duration: 0.3), value: progress.visited)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    @Previewable @Query(sort: \Prefecture.id) var prefs: [Prefecture]
    IrohaStatsBar(prefectures: prefs, mapViewModel: vm)
        .padding()
        .background(Color.irohaWashi)
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
