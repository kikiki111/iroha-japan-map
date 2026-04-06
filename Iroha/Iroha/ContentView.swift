//
//  ContentView.swift
//  Iroha
//
//  Created by 西野達哉 on 2026/04/05.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var mapViewModel = MapViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                JapanMapView(viewModel: mapViewModel)
                    .navigationTitle("地図")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("地図", systemImage: "map")
            }

            NavigationStack {
                TimelineView(mapViewModel: mapViewModel)
            }
            .tabItem {
                Label("タイムライン", systemImage: "calendar")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Visit.self, inMemory: true)
}
