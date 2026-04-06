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
            .navigationTitle("地図")
            .toolbar { toolbarContent }
            .sheet(item: $mapViewModel.focusedPrefecture) { prefecture in
                AddVisitView(initialPrefectureName: prefecture.name)
                    .presentationDetents([.medium, .large])
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
