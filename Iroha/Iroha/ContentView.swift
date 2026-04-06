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
            JapanMapView(mapViewModel: mapViewModel)
                .tabItem {
                    Label("地図", systemImage: "map")
                }

            TimelineView(mapViewModel: mapViewModel)
                .tabItem {
                    Label("タイムライン", systemImage: "clock")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
