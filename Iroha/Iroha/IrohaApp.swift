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
        // Prefecture は static struct (Iroha/Models/Prefecture.swift) として
        // SwiftData の外に持つ。Visit / VisitPhoto / TravelStyleRecord が SwiftData の管理対象。
        // 旅行スタイルのプリセットも Prefecture 同様に静的テーブルで持ち、seed しない
        // (複数端末での重複を避けるため)。TravelStyleRecord はユーザー操作の結果だけを保存する。
        //
        // CloudKit 同期はユーザの UserDefaults `cloud_sync_enabled` 設定に従う。
        // ModelContainer は起動時に固定されるため、Settings での ON/OFF 切替時は
        // 「次回起動時に反映」アラートを出してアプリの再起動を促す。
        let schema = Schema([Visit.self, VisitPhoto.self, TravelStyleRecord.self])
        // UserDefaults 未設定時は default true。Apple ID サインイン中なら自動で iCloud 同期。
        // ユーザは Settings で OFF にできる。Apple 純正アプリ (メモ、写真) と同じ UX。
        let syncEnabled = (UserDefaults.standard.object(forKey: CloudSyncStatusObserver.syncEnabledKey) as? Bool) ?? true
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: syncEnabled
                ? .private("iCloud.com.qumo.Iroha")
                : .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // 起動時マイグレーション。順序は重要:
            //   1. prefectureID backfill + prefectureIDs seed
            //      (旧 Visit が VisitStats で集計対象になる / 複数県配列へ詰め替え)
            //   2. legacy 写真 → VisitPhoto 転記 (旧データは削除せず保持、Phase B で清掃)
            VisitPrefectureMigration.migrate(context: container.mainContext)
            PhotoMigration.migrate(context: container.mainContext)
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
