//
//  ProfileView.swift
//  Iroha
//
//  プロフィールタブ：旅の実績ダッシュボード

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]
    @Query(sort: \Visit.startDate, order: .reverse) private var visits: [Visit]

    private var visitedCount: Int { prefectures.filter(\.isVisited).count }
    private var totalVisits: Int { visits.count }
    private var tripCount: Int { TripDetector.detect(from: Array(visits)).count }

    private var conqueredRegionCount: Int {
        Region.allCases.filter { region in
            let group = prefectures.filter { $0.region == region }
            return !group.isEmpty && group.allSatisfy(\.isVisited)
        }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    MemoryCardView()

                    heroSection
                    threeColumnStats
                    regionDotsSection
                    milestoneSection
                    recentVisitsSection
                }
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("プロフィール")
                        .font(.system(size: 20, weight: .light, design: .serif))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.irohaSumi2)
                    }
                }
            }
        }
    }

    // MARK: - Hero section

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("全国制覇")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)

            HStack(alignment: .bottom, spacing: 6) {
                NurikakeNumber(value: visitedCount, fontSize: 56)
                Text("/ 47")
                    .font(.system(size: 16))
                    .foregroundColor(.irohaSumi3)
                    .padding(.bottom, 6)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.irohaWashi3)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.irohaFujiLt, .irohaFuji, .irohaFujiDk],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(visitedCount) / 47.0, height: 7)
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
    }

    // MARK: - 3-column stats

    private var threeColumnStats: some View {
        HStack(spacing: 0) {
            profileColumn(value: totalVisits, label: "訪問回数")
            Divider().frame(height: 40)
            profileColumn(value: tripCount, label: "旅行回数")
            Divider().frame(height: 40)
            profileColumn(value: conqueredRegionCount, label: "地方制覇")
        }
        .padding(.vertical, 10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.irohaWashi3, lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func profileColumn(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text(verbatim: "\(value)")
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(.irohaFujiDk)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.irohaSumi3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Region dots

    private var regionDotsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("地方別")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 14)

            HStack(spacing: 5) {
                ForEach(Region.allCases) { region in
                    let group = prefectures.filter { $0.region == region }
                    let visited = group.filter(\.isVisited).count
                    let total = group.count
                    let isFull = visited == total && total > 0
                    let ratio = total > 0 ? CGFloat(visited) / CGFloat(total) : 0

                    Circle()
                        .fill(isFull ? Color.irohaFujiDk : Color.irohaWashi3)
                        .frame(width: 14, height: 14)
                        .overlay(
                            !isFull && ratio > 0 ?
                            Circle()
                                .fill(Color.irohaFuji)
                                .mask(
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .frame(height: 7)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(height: 14)
                                )
                            : nil
                        )
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Milestone

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("マイルストーン")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 14)

            HStack(spacing: 5) {
                milestoneBadge("1県目", achieved: visitedCount >= 1)
                milestoneBadge("25/47", achieved: UserDefaults.standard.bool(forKey: "milestone_25_shown"))
                milestoneBadge("47/47", achieved: UserDefaults.standard.bool(forKey: "milestone_47_shown"))
            }
            .padding(.horizontal, 20)
        }
    }

    private func milestoneBadge(_ text: String, achieved: Bool) -> some View {
        Text(achieved ? "\u{2713} \(text)" : text)
            .font(.system(size: 13))
            .foregroundColor(achieved ? .irohaFujiDk : .irohaSumi3)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(achieved ? Color.irohaFujiLt.opacity(0.3) : Color.irohaWashi2)
            .clipShape(Capsule())
    }

    // MARK: - Recent visits

    private var recentVisitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近の訪問")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 14)

            ForEach(Array(visits.prefix(3))) { visit in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.visitColor(count: prefectures.first(where: { $0.name == visit.prefectureName })?.visitCount ?? 0))
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(visit.prefectureName)
                                .font(.system(size: 16, weight: .bold))
                            if visit.effectiveTag != .none {
                                VisitTagBadge(tag: visit.effectiveTag)
                            }
                        }
                        if !visit.note.isEmpty {
                            Text(visit.note)
                                .font(.system(size: 13))
                                .foregroundColor(.irohaSumi2)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Text(visit.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundColor(.irohaSumi3)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Border helper

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.reduce(into: Path()) { path, edge in
            switch edge {
            case .top:    path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: width))
            case .bottom: path.addRect(CGRect(x: 0, y: rect.height - width, width: rect.width, height: width))
            case .leading:  path.addRect(CGRect(x: 0, y: 0, width: width, height: rect.height))
            case .trailing: path.addRect(CGRect(x: rect.width - width, y: 0, width: width, height: rect.height))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
