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

    var body: some View {
        TabView {
            MapTabView(mapViewModel: mapViewModel)
                .tabItem { Label("地図", systemImage: "map") }

            TimelineView(mapViewModel: mapViewModel)
                .tabItem { Label("履歴", systemImage: "clock") }
        }
        .tint(Color(hex: "#7F77DD"))
    }
}

// MARK: - MapTabView

/// 地図タブ：StatsBarView + JapanMapView を NavigationStack でまとめ、シェアボタンを配置
private struct MapTabView: View {
    @Bindable var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    /// マイルストーン検出用の前回状態
    @State private var previousVisitedCount: Int = 0
    @State private var previousRegionCounts: [Region: Int] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    StatsBarView(mapViewModel: mapViewModel)
                    JapanMapView(mapViewModel: mapViewModel)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color.irohaBackground)
            .navigationTitle("地図")
            .toolbar { toolbarContent }
            .sheet(item: $mapViewModel.focusedPrefecture) { prefecture in
                AddVisitView(initialPrefectureName: prefecture.name)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                previousVisitedCount = mapViewModel.visitedPrefectureCount(prefectures: prefectures)
                previousRegionCounts = mapViewModel.regionVisitedCounts(prefectures: prefectures)
            }
            .onChange(of: prefectures.map(\.visitCount)) { oldCounts, newCounts in
                guard oldCounts != newCounts else { return }
                let oldVisitedCount = previousVisitedCount
                let oldRegionCounts = previousRegionCounts

                // キャッシュ更新
                previousVisitedCount = mapViewModel.visitedPrefectureCount(prefectures: prefectures)
                previousRegionCounts = mapViewModel.regionVisitedCounts(prefectures: prefectures)

                // マイルストーン検出
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

    // MARK: - Milestone animation execution

    private func executeMilestoneAnimation(_ milestone: MilestoneType) {
        switch milestone {
        case .firstVisit:
            // CSS transition が自動で 0.4s フェードを処理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mapViewModel.pendingMilestone = nil
            }

        case .halfConquest:
            // 地図パルス: 1.0 → 1.02 → 1.0 (0.8s)
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
            // JS flashPrefectures が JapanMapWebViewWrapper.updateUIView で実行される
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                mapViewModel.pendingMilestone = nil
            }

        case .nationalConquest:
            // JS waveAnimation が JapanMapWebViewWrapper.updateUIView で実行される
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                mapViewModel.pendingMilestone = nil
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                ShareManager.shareMap(prefectures: prefectures)
            } label: {
                Label("シェア", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("地図をシェア")
        }
        if mapViewModel.focusedPrefecture != nil {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("クリア") {
                    mapViewModel.clearFocus()
                }
                .accessibilityLabel("フォーカスをクリア")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
