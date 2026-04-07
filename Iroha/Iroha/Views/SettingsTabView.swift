//
//  SettingsTabView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 設定・データ管理タブ
struct SettingsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [Visit]

    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                dataSection
                aboutSection
            }
            .navigationTitle("設定")
        }
    }

    // MARK: - Data management

    private var dataSection: some View {
        Section("データ管理") {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("データをリセット", systemImage: "arrow.clockwise")
            }
            .confirmationDialog(
                "すべてのデータをリセットしますか？",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("リセット", role: .destructive) { resetAll() }
            } message: {
                Text("すべての訪問記録が削除されます。この操作は取り消せません。")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("バージョン")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("いろは — 47都道府県の旅の記録")
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
        }
    }

    // MARK: - Actions

    private func resetAll() {
        for visit in visits {
            modelContext.delete(visit)
        }
        UserDefaults.standard.removeObject(forKey: "milestone_25_shown")
        UserDefaults.standard.removeObject(forKey: "milestone_47_shown")
        for region in Region.allCases {
            UserDefaults.standard.removeObject(forKey: "region_\(region.rawValue)_shown")
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsTabView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
