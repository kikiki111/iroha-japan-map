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
    @AppStorage("onboarding_done") private var onboardingDone = false

    var body: some View {
        ZStack {
            TabView {
                MapTabView(mapViewModel: mapViewModel)
                    .tabItem {
                        Label("地図", systemImage: "globe.asia.australia")
                    }

                TimelineView(mapViewModel: mapViewModel)
                    .tabItem {
                        Label("旅の記録", systemImage: "book")
                    }

                ProfileView()
                    .tabItem {
                        Label("プロフ", systemImage: "person")
                    }
            }
            .tint(Color.irohaFujiDk)

            if !onboardingDone {
                OnboardingView()
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - MapTabView

/// 地図タブ
private struct MapTabView: View {
    @Bindable var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var previousVisitedCount: Int = 0
    @State private var previousRegionCounts: [Region: Int] = [:]
    @State private var showSearch = false
    @State private var selectedPrefecture: Prefecture?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    JapanMapView(mapViewModel: mapViewModel)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    IrohaStatsBar(prefectures: prefectures, mapViewModel: mapViewModel)
                }
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) {
                if let toast = mapViewModel.bookmarkToast {
                    toastView(toast)
                }
            }
            .overlay {
                if showSearch {
                    SearchOverlayView(
                        prefectures: prefectures,
                        isPresented: $showSearch,
                        onSelect: { pref in
                            showSearch = false
                            selectedPrefecture = pref
                        }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: mapViewModel.bookmarkToast)
            .sheet(item: $selectedPrefecture) { prefecture in
                PrefectureDetailSheet(prefecture: prefecture)
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
            }
            .onAppear {
                previousVisitedCount = mapViewModel.visitedPrefectureCount(prefectures: prefectures)
                previousRegionCounts = mapViewModel.regionVisitedCounts(prefectures: prefectures)
            }
            .onChange(of: prefectures.map(\.visitCount)) { oldCounts, newCounts in
                guard oldCounts != newCounts else { return }
                let oldVisitedCount = previousVisitedCount
                let oldRegionCounts = previousRegionCounts
                previousVisitedCount = mapViewModel.visitedPrefectureCount(prefectures: prefectures)
                previousRegionCounts = mapViewModel.regionVisitedCounts(prefectures: prefectures)
                mapViewModel.detectMilestone(
                    oldVisitedCount: oldVisitedCount,
                    oldRegionCounts: oldRegionCounts,
                    prefectures: prefectures
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
        case .halfConquest:
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
        case .regionConquest:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mapViewModel.pendingMilestone = nil
            }
        case .nationalConquest:
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                mapViewModel.pendingMilestone = nil
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            NurikakeText(text: "いろは", fontSize: 20, topColor: .irohaFuji, bottomColor: .irohaWashi3)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSearch.toggle()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(showSearch ? .irohaFujiDk : .irohaSumi2)
                    .frame(width: 28, height: 28)
                    .background(
                        showSearch
                            ? Color.irohaFuji.opacity(0.14)
                            : Color.irohaWashi2
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(showSearch ? Color.irohaFujiLt : Color.irohaWashi3, lineWidth: 0.5))
            }
        }
    }

    // MARK: - Toast

    private func toastView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.irohaSumi.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        mapViewModel.bookmarkToast = nil
                    }
                }
            }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
