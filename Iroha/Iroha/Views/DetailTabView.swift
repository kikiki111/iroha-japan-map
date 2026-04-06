//
//  DetailTabView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 地方別の達成状況を一覧表示するタブ
struct DetailTabView: View {
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var selectedRegion: Region?

    private var visitedCount: Int { prefectures.filter(\.isVisited).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    overallProgressCard
                    regionList
                }
                .padding()
            }
            .background(Color.irohaBackground)
            .navigationTitle("詳細")
            .sheet(item: $selectedRegion) { region in
                RegionDetailView(region: region, prefectures: prefectures.filter { $0.region == region })
                    .presentationDetents([.large])
            }
        }
    }

    // MARK: - Overall progress

    private var overallProgressCard: some View {
        VStack(spacing: 8) {
            Text("全国制覇進捗")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(verbatim: "\(visitedCount)/47")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#7F77DD"))
            ProgressView(value: Double(visitedCount) / 47.0)
                .tint(Color(hex: "#7F77DD"))
            Text(String(format: "達成率 %.1f%%", Double(visitedCount) / 47.0 * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.irohaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    // MARK: - Region list

    private var regionList: some View {
        VStack(spacing: 8) {
            Text("エリア別達成状況")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Region.allCases, id: \.self) { region in
                let group = prefectures.filter { $0.region == region }
                let visited = group.filter(\.isVisited).count
                let total = group.count
                RegionCard(region: region, visited: visited, total: total)
                    .onTapGesture { selectedRegion = region }
            }
        }
    }
}

// MARK: - RegionCard

private struct RegionCard: View {
    let region: Region
    let visited: Int
    let total: Int

    private var ratio: Double { total > 0 ? Double(visited) / Double(total) : 0 }
    private var isComplete: Bool { visited == total && total > 0 }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(region.localizedName)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(verbatim: "\(visited)/\(total)県")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if isComplete {
                        Text("制覇完了")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#534AB7"))
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            Text(String(format: "%.0f%%", ratio * 100))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(region.color)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.irohaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - RegionDetailView

struct RegionDetailView: View {
    let region: Region
    let prefectures: [Prefecture]

    @Environment(\.dismiss) private var dismiss

    private var visited: [Prefecture] { prefectures.filter(\.isVisited) }
    private var unvisited: [Prefecture] { prefectures.filter { !$0.isVisited } }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerStats
                    if !visited.isEmpty {
                        prefectureSection(title: "訪問済み", list: visited, isVisited: true)
                    }
                    if !unvisited.isEmpty {
                        prefectureSection(title: "未訪問", list: unvisited, isVisited: false)
                    }
                }
                .padding()
            }
            .background(Color.irohaBackground)
            .navigationTitle(region.localizedName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    private var headerStats: some View {
        HStack(spacing: 0) {
            statColumn(label: "訪問済み", value: "\(visited.count)", color: region.color)
            Divider().frame(height: 40)
            statColumn(label: "未訪問", value: "\(unvisited.count)", color: .secondary)
            Divider().frame(height: 40)
            let pct = prefectures.isEmpty ? 0 : Double(visited.count) / Double(prefectures.count) * 100
            statColumn(label: "達成率", value: String(format: "%.0f%%", pct), color: region.color)
        }
        .padding()
        .background(Color.irohaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func statColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func prefectureSection(title: String, list: [Prefecture], isVisited: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(list) { pref in
                    PrefectureCard(prefecture: pref, isVisited: isVisited, regionColor: region.color)
                }
            }
        }
    }
}

// MARK: - PrefectureCard

private struct PrefectureCard: View {
    let prefecture: Prefecture
    let isVisited: Bool
    let regionColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(prefecture.name)
                .font(.subheadline)
                .fontWeight(.medium)
            if isVisited {
                Text(verbatim: "\(prefecture.visitCount)回訪問")
                    .font(.caption2)
                    .foregroundStyle(regionColor)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(isVisited ? regionColor.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isVisited ? regionColor.opacity(0.3) : .clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    DetailTabView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
