//
//  ContentView.swift
//  Iroha
//
//  Created by 西野達哉 on 2026/04/05.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var mapViewModel = MapViewModel()
    @State private var cloudSyncStatus = CloudSyncStatusObserver()
    @AppStorage("onboarding_done") private var onboardingDone = false
    @AppStorage("cloud_sync_onboarding_done") private var cloudSyncOnboardingDone = false
    @AppStorage("appearance_mode") private var appearanceMode: Int = 0

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        // 旅行スタイルのカタログを全画面へ配る。@Query の単一オーナーなので
        // ローカル保存も CloudKit のリモート反映もここ経由で再描画に載る。
        TravelStyleCatalogProvider {
            ZStack {
                TabView {
                    MapTabView(mapViewModel: mapViewModel)
                        .tabItem {
                            Label("地図", systemImage: "globe.asia.australia")
                        }

                    TimelineView(mapViewModel: mapViewModel)
                        .tabItem {
                            Label("旅の軌跡", systemImage: "book")
                        }

                    JourneyTrackerView()
                        .tabItem {
                            Label("記録", systemImage: "flag.fill")
                        }
                }
                .tint(Color.irohaFujiDk)

                if !onboardingDone {
                    OnboardingView()
                        .transition(.opacity)
                }
            }
        }
        .environment(cloudSyncStatus)
        .preferredColorScheme(colorScheme)
        .sheet(isPresented: Binding(
            get: { onboardingDone && !cloudSyncOnboardingDone },
            set: { _ in }
        )) {
            CloudSyncOnboardingView()
        }
        .task {
            await cloudSyncStatus.refreshAccountStatus()
        }
    }
}

// MARK: - MapTabView

/// 地図タブ
private struct MapTabView: View {
    @Bindable var mapViewModel: MapViewModel

    @Query(sort: \Visit.startDate, order: .reverse) private var visits: [Visit]

    @State private var previousVisitedCount: Int = 0
    @State private var showBadgeCollection = false
    @State private var previousRegionCounts: [Region: Int] = [:]
    @State private var suggestionDismissedRegion: Region?
    @State private var sakuraIntensity: SakuraEffectView.Intensity?

    private var stats: VisitStats { VisitStats(visits: visits) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    displayModeBar

                    JapanMapView(mapViewModel: mapViewModel)
                        .padding(.horizontal, 16)

                    regionSuggestionView

                    IrohaStatsBar(mapViewModel: mapViewModel)
                }
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay(alignment: .top) {
                if let toast = mapViewModel.milestoneToast {
                    milestoneToastView(toast)
                }
            }
            .overlay {
                if let intensity = sakuraIntensity {
                    SakuraEffectView(intensity: intensity)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showBadgeCollection = true
                } label: {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.irohaFujiDk)
                        .frame(width: 50, height: 50)
                        .background(Color.irohaWashi)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                }
                .padding(.bottom, 24)
                .padding(.trailing, 16)
            }
            .animation(.easeInOut(duration: 0.3), value: mapViewModel.milestoneToast)
            .sheet(isPresented: $showBadgeCollection) {
                NavigationStack {
                    ScrollView {
                        BadgeCollectionView(visits: Array(visits))
                            .padding(.bottom, 20)
                    }
                    .background(Color.irohaWashi)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("コレクション")
                                .font(.system(size: 18, weight: .light, design: .serif))
                                .tracking(1)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showBadgeCollection = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.irohaSumi2)
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.70), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground(Color.irohaWashi)
            }
            .sheet(item: $mapViewModel.focusedPrefecture) { prefecture in
                PrefectureDetailSheet(prefecture: prefecture)
                    .presentationDetents([.fraction(0.70), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(Color.irohaWashi)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .onAppear {
                let s = stats
                previousVisitedCount = s.visitedCount
                previousRegionCounts = mapViewModel.regionVisitedCounts(stats: s)
            }
            .onChange(of: stats.signature) { _, _ in
                let s = stats
                let oldVisitedCount = previousVisitedCount
                let oldRegionCounts = previousRegionCounts
                previousVisitedCount = s.visitedCount
                previousRegionCounts = mapViewModel.regionVisitedCounts(stats: s)
                mapViewModel.detectMilestone(
                    oldVisitedCount: oldVisitedCount,
                    oldRegionCounts: oldRegionCounts,
                    stats: s
                )
            }
            .onChange(of: mapViewModel.pendingMilestone) { _, milestone in
                guard let milestone else { return }
                executeMilestoneAnimation(milestone)
            }
        }
    }

    // MARK: - Milestone animation

    private func executeMilestoneAnimation(_ milestone: MilestoneType) {
        switch milestone {
        case .firstVisit:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mapViewModel.pendingMilestone = nil
            }
        case .countMilestone(let count):
            mapViewModel.milestoneToast = "\(count)県達成！"
            withAnimation(.easeInOut(duration: 0.3)) {
                mapViewModel.mapScale = 1.01
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    mapViewModel.mapScale = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                mapViewModel.pendingMilestone = nil
            }
        case .halfConquest:
            mapViewModel.milestoneToast = "25県達成！半分制覇！"
            sakuraIntensity = .light
            withAnimation(.easeInOut(duration: 0.4)) {
                mapViewModel.mapScale = 1.02
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    mapViewModel.mapScale = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                mapViewModel.pendingMilestone = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + SakuraEffectView.Intensity.light.totalDuration) {
                sakuraIntensity = nil
            }
        case .regionConquest:
            sakuraIntensity = .medium
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mapViewModel.pendingMilestone = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + SakuraEffectView.Intensity.medium.totalDuration) {
                sakuraIntensity = nil
            }
        case .nationalConquest:
            sakuraIntensity = .grand
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                mapViewModel.pendingMilestone = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + SakuraEffectView.Intensity.grand.totalDuration) {
                sakuraIntensity = nil
            }
        }
    }

    // MARK: - Display Mode Bar

    private var displayModeBar: some View {
        HStack(spacing: 8) {
            ForEach(MapDisplayMode.allCases, id: \.self) { mode in
                let isActive = mapViewModel.displayMode == mode
                let activeColor: Color = mode == .all ? .irohaFujiDk : .irohaSumi
                Button {
                    mapViewModel.displayMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                        .foregroundColor(isActive ? .white : .irohaSumi2)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(isActive ? activeColor : Color.irohaWashi2)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Region Suggestion

    @ViewBuilder
    private var regionSuggestionView: some View {
        if let suggestion = mapViewModel.closestRegionSuggestion(stats: stats),
           suggestionDismissedRegion != suggestion.region {
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    Text("あと")
                        .foregroundColor(.irohaSumi2)
                    Text("\(suggestion.remaining)")
                        .foregroundColor(.irohaFujiDk)
                        .fontWeight(.semibold)
                    Text("県で")
                        .foregroundColor(.irohaSumi2)
                    Text("\(suggestion.region.localizedName)")
                        .foregroundColor(.irohaFujiDk)
                        .fontWeight(.semibold)
                    Text("制覇")
                        .foregroundColor(.irohaSumi2)

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            suggestionDismissedRegion = suggestion.region
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.irohaSumi3)
                            .frame(width: 32, height: 32)
                    }
                    .padding(.leading, 4)
                    .accessibilityLabel("候補を閉じる")
                }
                .font(.system(size: 13, design: .serif))

                HStack(spacing: 6) {
                    ForEach(suggestion.unvisited) { pref in
                        Button {
                            mapViewModel.focus(prefecture: pref)
                        } label: {
                            Text(pref.name)
                                .font(.system(size: 11))
                                .foregroundColor(.irohaFujiDk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.irohaFuji.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 16)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            NurikakeText(text: "いろは", fontSize: 32, fillFromTop: true)
        }
    }

    // MARK: - Milestone Toast

    private func milestoneToastView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold, design: .serif))
            .foregroundStyle(Color.irohaFujiDk)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.irohaFujiLt.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        mapViewModel.milestoneToast = nil
                    }
                }
            }
    }

}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [Visit.self], inMemory: true)
}
