//
//  IrohaApp.swift
//  Iroha
//
//  Created by 西野達哉 on 2026/04/05.
//

import SwiftUI
import SwiftData

@main
struct IrohaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Prefecture.self, Visit.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedPrefecturesIfNeeded(into: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Prefecture seeding

/// DB に Prefecture が 1 件もない場合に全 47 件を挿入する
private func seedPrefecturesIfNeeded(into context: ModelContext) {
    let descriptor = FetchDescriptor<Prefecture>()
    guard (try? context.fetch(descriptor))?.isEmpty == true else { return }
    for row in Prefecture.seedRows {
        context.insert(Prefecture(
            id: row.id, name: row.name, region: row.region,
            latitude: row.lat, longitude: row.lon,
            distanceFromTokyo: row.dist
        ))
    }
    try? context.save()
}
