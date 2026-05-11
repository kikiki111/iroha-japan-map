//
//  BadgeCollectionView.swift
//  Iroha
//

import SwiftUI

struct BadgeCollectionView: View {
    let visits: [Visit]

    @State private var selectedTier: TravelerTier = .beginner
    @State private var selectedBadge: Badge?

    private var stats: VisitStats { VisitStats(visits: visits) }

    private var currentTier: TravelerTier {
        TravelerTier.currentTier(visits: visits, stats: stats)
    }

    private var totalEarned: Int {
        let s = stats
        return Badge.allCases.filter { $0.isEarned(visits: visits, stats: s) }.count
    }

    private func tierEarnedCount(_ tier: TravelerTier) -> Int {
        let s = stats
        return Badge.badges(for: tier).filter { $0.isEarned(visits: visits, stats: s) }.count
    }

    private func isTierUnlocked(_ tier: TravelerTier) -> Bool {
        tier.isUnlocked(visits: visits, stats: stats)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 0) {
                Text("コレクション")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.irohaSumi3)
                    .tracking(2)
                Spacer()
                Text(verbatim: "\(totalEarned)/\(Badge.allCases.count)")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundColor(.irohaSumi3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Tier selector
            tierSelector

            // Tier progress
            tierProgress

            // Badge grid
            VStack(spacing: 14) {
                ForEach(BadgeCategory.allCases, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.irohaCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.irohaWashi3, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
        }
        .sheet(item: $selectedBadge) { badge in
            badgeDetailSheet(badge)
                .presentationDetents([.fraction(0.35)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(Color.irohaWashi)
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }

    // MARK: - Tier selector

    private var tierSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TravelerTier.allCases) { tier in
                    let unlocked = isTierUnlocked(tier)
                    let isSelected = selectedTier == tier
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTier = tier
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if !unlocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                            }
                            Text(tier.displayName)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white : unlocked ? .irohaSumi2 : .irohaSumi3.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(isSelected ? tier.tierColor : Color.irohaWashi2)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Tier progress

    private var tierProgress: some View {
        let earned = tierEarnedCount(selectedTier)
        let unlocked = isTierUnlocked(selectedTier)

        return VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.irohaSumi3.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(selectedTier.tierColor.opacity(unlocked ? 1 : 0.3))
                        .frame(width: geo.size.width * CGFloat(earned) / 12.0)
                }
            }
            .frame(height: 6)

            HStack {
                Text(verbatim: "\(selectedTier.subtitle)")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(.irohaSumi3)
                Spacer()
                if unlocked {
                    Text(verbatim: "\(earned)/12")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(selectedTier.tierColor)
                } else {
                    let prev = TravelerTier(rawValue: selectedTier.rawValue - 1)!
                    let prevEarned = tierEarnedCount(prev)
                    let needed = selectedTier.thresholdFromPrevious - prevEarned
                    Text("\(prev.displayName)であと\(needed)個")
                        .font(.system(size: 11))
                        .foregroundColor(.irohaSumi3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    // MARK: - Category section

    private func categorySection(_ category: BadgeCategory) -> some View {
        let unlocked = isTierUnlocked(selectedTier)
        let s = stats

        return VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundColor(.irohaSumi2)
                .tracking(1)

            let badges = Badge.badges(for: selectedTier, category: category)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(badges) { badge in
                    let earned = badge.isEarned(visits: visits, stats: s)
                    VStack(spacing: 4) {
                        BadgeStampView(badge: badge, earned: earned && unlocked, locked: !unlocked)
                        Text(earned && unlocked ? badge.displayName : "???")
                            .font(.system(size: 10))
                            .foregroundColor(earned && unlocked ? .irohaSumi : .irohaSumi3.opacity(0.4))
                            .lineLimit(1)
                    }
                    .onTapGesture {
                        if earned && unlocked { selectedBadge = badge }
                    }
                }
            }
        }
    }

    // MARK: - Detail sheet

    private func badgeDetailSheet(_ badge: Badge) -> some View {
        VStack(spacing: 12) {
            BadgeStampView(badge: badge, earned: true)
                .scaleEffect(1.3)
                .padding(.top, 20)

            Text(badge.displayName)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(badge.stampColor)

            Text(badge.tier.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(badge.tier.tierColor)
                .clipShape(Capsule())

            Text(badge.description)
                .font(.system(size: 13))
                .foregroundColor(.irohaSumi2)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
