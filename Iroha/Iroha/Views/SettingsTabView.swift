//
//  SettingsTabView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 設定・データ管理タブ
struct SettingsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]
    @Query private var visits: [Visit]

    @State private var showResetConfirmation = false
    @State private var showResetVisitsConfirmation = false

    private var visitedCount: Int { prefectures.filter(\.isVisited).count }
    private var conquestRate: Double { Double(visitedCount) / 47.0 * 100 }

    var body: some View {
        NavigationStack {
            List {
                statusSection
                dataSection
                aboutSection
            }
            .navigationTitle("設定")
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "#7F77DD"))
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "訪問済み: \(visitedCount)県 / 47県")
                        .font(.subheadline)
                    Text(String(format: "達成率 %.1f%%", conquestRate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f%%", conquestRate))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: "#7F77DD"))
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Data management

    private var dataSection: some View {
        Section("データ管理") {
            Button(role: .destructive) {
                showResetVisitsConfirmation = true
            } label: {
                Label("訪問記録をリセット", systemImage: "clock.arrow.circlepath")
            }
            .confirmationDialog(
                "訪問記録をリセットしますか？",
                isPresented: $showResetVisitsConfirmation,
                titleVisibility: .visible
            ) {
                Button("リセット", role: .destructive) { resetVisits() }
            } message: {
                Text("すべての訪問記録が削除されます。この操作は取り消せません。")
            }

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("すべてリセット", systemImage: "arrow.clockwise")
            }
            .confirmationDialog(
                "すべてのデータをリセットしますか？",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("すべてリセット", role: .destructive) { resetAll() }
            } message: {
                Text("すべての訪問記録とマイルストーンの達成状況が削除されます。この操作は取り消せません。")
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

    private func resetVisits() {
        for visit in visits {
            modelContext.delete(visit)
        }
    }

    private func resetAll() {
        resetVisits()
        // マイルストーン達成状況もリセット
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
