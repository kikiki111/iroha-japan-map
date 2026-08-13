//
//  StatsBarView.swift
//  Iroha
//
//  地図下部の統計エリア（塗りかけデザイン）

import SwiftUI
import SwiftData

/// 地図の下に表示する統計バー
struct IrohaStatsBar: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Visit.startDate, order: .reverse) private var visits: [Visit]

    private var stats: VisitStats { VisitStats(visits: visits) }
    private var visitedCount: Int { mapViewModel.visitedPrefectureCount(stats: stats) }
    private var totalVisits: Int { mapViewModel.totalVisitCount(stats: stats) }
    private var ratio: Double { mapViewModel.achievementRatio(stats: stats) }

    @State private var selectedRegion: MapViewModel.RegionProgress?

    var body: some View {
        VStack(spacing: 0) {
            // Main stats row
            HStack(alignment: .bottom, spacing: 5) {
                NurikakeNumber(value: visitedCount, fontSize: 36, ratio: ratio)
                Text("/ 47")
                    .font(.system(size: 14))
                    .foregroundColor(.irohaSumi3)
                    .padding(.bottom, 5)
                Spacer()
                // 居住県がある場合のみ表示（0 件のときは従来どおりの見た目）。
                // 隣の達成率と同じ 13pt に揃え、色だけ金茶にして区別する。
                if stats.residenceCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "house")
                            .font(.system(size: 11))
                        Text(verbatim: "\(stats.residenceCount)")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.irohaSumikaDk)
                    .padding(.bottom, 5)
                    .accessibilityLabel("住んだ県 \(stats.residenceCount)")
                }
                Text(String(format: "%.0f%%", ratio * 100))
                    .font(.system(size: 13))
                    .foregroundColor(.irohaSumi3)
                    .padding(.bottom, 5)
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)

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
            HStack(spacing: 0) {
                ForEach(mapViewModel.regionProgressList(stats: stats).reversed()) { progress in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedRegion?.id == progress.id {
                                selectedRegion = nil
                            } else {
                                selectedRegion = progress
                            }
                        }
                    } label: {
                        regionDot(progress: progress)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(progress.region.localizedName) \(progress.visited)/\(progress.total)")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 8)
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
    IrohaStatsBar(mapViewModel: vm)
        .padding()
        .background(Color.irohaWashi)
        .modelContainer(for: [Visit.self], inMemory: true)
}
