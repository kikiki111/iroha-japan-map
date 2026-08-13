//
//  SettingsView.swift
//  Iroha
//
//  プロフィールから push 遷移する設定画面

import SwiftUI
import SwiftData
import StoreKit

/// 設定画面（プロフィールからpush遷移）
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(CloudSyncStatusObserver.self) private var cloudSyncStatus
    @Query private var visits: [Visit]

    @AppStorage("appearance_mode") private var appearanceMode: Int = 0
    @AppStorage(CloudSyncStatusObserver.syncEnabledKey) private var syncEnabled: Bool = true
    @State private var showResetConfirmation = false
    @State private var showResetFinalConfirmation = false
    @State private var showAppResetConfirmation = false
    @State private var showAppResetFinalConfirmation = false
    @State private var showSyncRestartNotice = false

    private var appearanceLabel: String {
        switch appearanceMode {
        case 1: return "ライト"
        case 2: return "ダーク"
        default: return "システム連動"
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                displaySection
                cloudSyncSection
                dataSection
                aboutSection
            }
            .padding(.bottom, 24)
        }
        .background(Color.irohaWashi)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("設定")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .tracking(1)
            }
        }
        .alert("本当にリセットしますか？", isPresented: $showResetConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                showResetFinalConfirmation = true
            }
        } message: {
            Text("この操作は元に戻せません。")
        }
        .alert(
            syncEnabled ? "iCloud 上のデータも削除されます" : "すべてのデータを削除しますか？",
            isPresented: $showResetFinalConfirmation
        ) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                resetAll()
            }
        } message: {
            Text(
                syncEnabled
                    ? "iCloud 同期が有効です。削除はクラウドにも反映され、他の端末からも記録が消えます。続行しますか？"
                    : "すべての旅行記録・写真・マイルストーンが削除されます。"
            )
        }
        .alert("次回起動時に反映されます", isPresented: $showSyncRestartNotice) {
            Button("OK") {}
        } message: {
            Text("iCloud 同期の設定変更は、アプリを終了して再起動した後から有効になります。")
        }
        .alert("アプリを初期化しますか？", isPresented: $showAppResetConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("初期化", role: .destructive) {
                showAppResetFinalConfirmation = true
            }
        } message: {
            Text("この操作は元に戻せません。")
        }
        .alert("すべてのデータと設定を削除しますか？", isPresented: $showAppResetFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("初期化", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("アプリが新規インストール時の状態に戻ります。")
        }
    }

    // MARK: - Sections

    private var cloudSyncSection: some View {
        VStack(spacing: 0) {
            sectionHeader("iCloud 同期")
            settingsGroup {
                HStack(spacing: 10) {
                    settingsIcon(icon: "icloud", bg: .irohaFuji)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("自動同期")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.irohaSumi)
                        Text("写真を含む記録を iCloud に保存")
                            .font(.system(size: 11))
                            .foregroundColor(.irohaSumi3)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { syncEnabled },
                        set: { newValue in
                            syncEnabled = newValue
                            showSyncRestartNotice = true
                        }
                    ))
                    .labelsHidden()
                    .tint(.irohaFuji)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Divider().padding(.leading, 50)

                HStack(spacing: 10) {
                    settingsIcon(icon: cloudSyncStatus.state.iconName, bg: cloudSyncStatus.state.displayColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("状態")
                            .font(.system(size: 13))
                            .foregroundColor(.irohaSumi3)
                        Text(cloudSyncStatus.state.displayLabel)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(cloudSyncStatus.state.displayColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
    }

    private var displaySection: some View {
        VStack(spacing: 0) {
            sectionHeader("表示")
            settingsGroup {
                appearanceRow
                Divider().padding(.leading, 50)
                memoryNotificationRow
                Divider().padding(.leading, 50)
                travelStyleRow
            }
        }
    }

    private var travelStyleRow: some View {
        NavigationLink(destination: TravelStyleSettingsView()) {
            HStack(spacing: 10) {
                settingsIcon(icon: "tag")
                VStack(alignment: .leading, spacing: 2) {
                    Text("旅行スタイル")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.irohaSumi)
                    Text("表示するスタイルの切り替えと追加")
                        .font(.system(size: 11))
                        .foregroundColor(.irohaSumi3)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.irohaSumi3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private var dataSection: some View {
        VStack(spacing: 0) {
            sectionHeader("データ")
            settingsGroup {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: 10) {
                        settingsIcon(icon: "exclamationmark.triangle.fill", bg: Color(hex: "#E05555"))
                        Text("全データをリセット")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.irohaSumi)
                        Spacer()
                        Text("実行")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#E05555"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                Divider().padding(.leading, 50)
                Button(role: .destructive) {
                    showAppResetConfirmation = true
                } label: {
                    HStack(spacing: 10) {
                        settingsIcon(icon: "arrow.counterclockwise.circle.fill", bg: Color(hex: "#E05555"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("アプリを初期化")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.irohaSumi)
                            Text("新規インストール時の状態に戻します")
                                .font(.system(size: 11))
                                .foregroundColor(.irohaSumi3)
                        }
                        Spacer()
                        Text("実行")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#E05555"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader("いろは について")
            settingsGroup {
                settingsRow(icon: nil, iconBg: nil, label: "バージョン", value: appVersion)
                Divider().padding(.leading, 14)
                privacyPolicyRow
                Divider().padding(.leading, 50)
                NavigationLink(destination: LicensesView()) {
                    HStack(spacing: 10) {
                        settingsIcon(icon: "doc.text", bg: .irohaSumi2)
                        Text("ライセンス")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.irohaSumi)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.irohaSumi3)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                Divider().padding(.leading, 50)
                feedbackRow
            }
        }
    }

    // MARK: - Memory card

    private var memoryNotificationRow: some View {
        HStack(spacing: 10) {
            settingsIcon(icon: "clock.arrow.circlepath")
            VStack(alignment: .leading, spacing: 2) {
                Text("今日の記憶")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.irohaSumi)
                Text("◯年前の今日の旅をホームに表示")
                    .font(.system(size: 11))
                    .foregroundColor(.irohaSumi3)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { UserDefaults.standard.object(forKey: "show_memory_card") as? Bool ?? true },
                set: { UserDefaults.standard.set($0, forKey: "show_memory_card") }
            ))
            .labelsHidden()
            .tint(.irohaFuji)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - Display rows

    private var appearanceRow: some View {
        HStack(spacing: 10) {
            settingsIcon(icon: "circle.lefthalf.filled")
            Text("外観")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.irohaSumi)
            Spacer()
            Picker("", selection: $appearanceMode) {
                Text("システム").tag(0)
                Text("ライト").tag(1)
                Text("ダーク").tag(2)
            }
            .pickerStyle(.menu)
            .tint(.irohaSumi2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - About rows

    private var privacyPolicyRow: some View {
        NavigationLink(destination: PrivacyPolicyView()) {
            HStack(spacing: 10) {
                settingsIcon(icon: "lock.fill", bg: .irohaSumi2)
                Text("プライバシーポリシー")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.irohaSumi)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.irohaSumi3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    private var feedbackRow: some View {
        Button {
            requestReview()
        } label: {
            HStack(spacing: 10) {
                settingsIcon(icon: "star.fill", bg: .irohaFuji)
                Text("レビューする")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.irohaSumi)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.irohaSumi3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Actions

    private func resetApp() {
        resetAll()
        UserDefaults.standard.removeObject(forKey: "onboarding_done")
        UserDefaults.standard.removeObject(forKey: "appearance_mode")
        UserDefaults.standard.removeObject(forKey: "last_backup_date")
        UserDefaults.standard.removeObject(forKey: "show_memory_card")
        CompanionSuggestionStore.clear()
        // 旅行スタイルのプリセット非表示とユーザー定義を破棄する。
        // resetAll() 側には入れない (アラート文言が記録・写真・マイルストーンに限っているため)。
        TravelStyleStore.clear(context: modelContext)
        appearanceMode = 0
    }

    private func resetAll() {
        let filenames = Set(visits.flatMap(\.allPhotoFilenames))
        for visit in visits {
            modelContext.delete(visit)
        }
        if (try? modelContext.save()) != nil {
            for filename in filenames {
                PhotoStorageManager.delete(filename: filename)
            }
        }
        clearMilestoneFlags()
    }

    private func clearMilestoneFlags() {
        for count in MapViewModel.countMilestones {
            UserDefaults.standard.removeObject(forKey: "milestone_\(count)_shown")
        }
        UserDefaults.standard.removeObject(forKey: "milestone_25_shown")
        UserDefaults.standard.removeObject(forKey: "milestone_47_shown")
        for region in Region.allCases {
            UserDefaults.standard.removeObject(forKey: "region_\(region.rawValue)_shown")
        }
    }

    // MARK: - Components

    // 実体は Views/Components/SettingsComponents.swift。
    // サブ画面 (TravelStyleSettingsView 等) と見た目を共有するため部品側に移した。

    private func sectionHeader(_ title: String) -> some View {
        SettingsSectionHeader(title)
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        SettingsGroup { content() }
    }

    private func settingsRow(icon: String?, iconBg: (any ShapeStyle)?, label: String, value: String) -> some View {
        SettingsRowLayout(
            icon: iconBg == nil ? nil : icon,
            iconBg: (iconBg as? Color) ?? .clear,
            label: label
        ) {
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.irohaSumi3)
                .monospacedDigit()
        }
    }

    private func settingsIcon(icon: String, bg: Color = .clear) -> some View {
        SettingsIcon(icon: icon, bg: bg)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Visit.self], inMemory: true)
    .environment(CloudSyncStatusObserver())
}
