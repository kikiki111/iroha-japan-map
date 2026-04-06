//
//  StatsBarView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 訪問統計サマリーと地方別達成バーを表示するカード
struct StatsBarView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]
    @State private var isRegionExpanded = false

    private var visitedCount: Int { mapViewModel.visitedPrefectureCount(prefectures: prefectures) }
    private var totalVisits: Int   { mapViewModel.totalVisitCount(prefectures: prefectures) }
    private var ratio: Double      { mapViewModel.achievementRatio(prefectures: prefectures) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ringStatsRow
            regionDisclosure
        }
        .padding()
        .background(Color.irohaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    private var ringStatsRow: some View {
        HStack(spacing: 16) {
            ConquestRingView(visited: visitedCount)
            VStack(alignment: .leading, spacing: 8) {
                StatItem(label: "訪問数", value: "\(visitedCount)/47")
                StatItem(label: "訪問回数計", value: "\(totalVisits)回")
            }
            Spacer()
            Text(String(format: "%.1f%%", ratio * 100))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "#7F77DD"))
        }
    }

    private var regionDisclosure: some View {
        DisclosureGroup(isExpanded: $isRegionExpanded) {
            VStack(spacing: 6) {
                ForEach(mapViewModel.regionProgressList(prefectures: prefectures)) { progress in
                    RegionProgressRow(progress: progress)
                }
            }
            .padding(.top, 6)
        } label: {
            Text("地方別達成")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityLabel("地方別達成バー")
    }
}

// MARK: - ConquestRingView

private struct ConquestRingView: View {
    let visited: Int
    private let total = 47
    private var ratio: CGFloat { CGFloat(visited) / CGFloat(total) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(Color(hex: "#7F77DD"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: ratio)
            VStack(spacing: 0) {
                Text(verbatim: "\(visited)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "#7F77DD"))
                Text("/47")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 72)
    }
}

// MARK: - StatItem

private struct StatItem: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
        }
    }
}

// MARK: - RegionProgressRow

private struct RegionProgressRow: View {
    let progress: MapViewModel.RegionProgress

    var body: some View {
        HStack(spacing: 8) {
            Text(progress.region.localizedName)
                .font(.caption)
                .frame(width: 44, alignment: .leading)
            ProgressView(value: progress.ratio)
                .tint(progress.region.color)
                .accessibilityLabel(
                    "\(progress.region.localizedName) \(progress.visited)県 / \(progress.total)県"
                )
            Text("\(progress.visited)/\(progress.total)")
                .font(.caption)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    StatsBarView(mapViewModel: vm)
        .padding()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
