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
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

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
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Prefecture seeding

/// DB に不足している Prefecture を補完する
private func seedPrefecturesIfNeeded(into context: ModelContext) {
    let descriptor = FetchDescriptor<Prefecture>()
    let existing = (try? context.fetch(descriptor)) ?? []
    let existingIDs = Set(existing.map(\.id))
    var didInsert = false

    for row in Prefecture.seedRows where !existingIDs.contains(row.id) {
        context.insert(Prefecture(
            id: row.id, name: row.name, nameKana: row.kana,
            region: row.region,
            latitude: row.lat, longitude: row.lon,
            distanceFromTokyo: row.dist
        ))
        didInsert = true
    }

    if didInsert {
        try? context.save()
    }
}
