//
//  SettingsView.swift
//  Iroha
//
//  プロフィールから push 遷移する設定画面

import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers

/// 設定画面（プロフィールからpush遷移）
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Query private var visits: [Visit]
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @AppStorage("appearance_mode") private var appearanceMode: Int = 0
    @AppStorage("last_backup_date") private var lastBackupTimestamp: Double = 0
    @State private var showResetConfirmation = false
    @State private var showResetFinalConfirmation = false
    @State private var showAppResetConfirmation = false
    @State private var showAppResetFinalConfirmation = false
    @State private var showBackupConfirmation = false
    @State private var showImportPicker = false
    @State private var showRestoreConfirmation = false
    @State private var pendingRestoreURL: URL?
    @State private var showRestoreSuccess = false
    @State private var restoredCount = 0
    @State private var showRestoreError = false
    @State private var errorAlertTitle = "復元に失敗しました"
    @State private var restoreErrorMessage = ""

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

    private var lastBackupLabel: String? {
        guard lastBackupTimestamp > 0 else { return nil }
        let date = Date(timeIntervalSince1970: lastBackupTimestamp)
        return date.formatted(.dateTime.year().month().day().hour().minute().locale(Locale(identifier: "ja_JP")))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                displaySection
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
        .alert("すべてのデータを削除しますか？", isPresented: $showResetFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                resetAll()
            }
        } message: {
            Text("すべての旅行記録・写真・マイルストーンが削除されます。")
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
        .alert("バックアップから復元しますか？", isPresented: $showRestoreConfirmation) {
            Button("キャンセル", role: .cancel) { pendingRestoreURL = nil }
            Button("復元") { performRestore() }
        } message: {
            Text("現在のデータはすべて上書きされます。写真は復元されません。現在の写真付き記録も写真なしになります。")
        }
        .alert("復元しました", isPresented: $showRestoreSuccess) {
            Button("OK") {}
        } message: {
            Text("\(restoredCount)件の旅行記録を読み込みました。")
        }
        .alert(errorAlertTitle, isPresented: $showRestoreError) {
            Button("OK") {}
        } message: {
            Text(restoreErrorMessage)
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                pendingRestoreURL = url
                showRestoreConfirmation = true
            case .failure(let error):
                errorAlertTitle = "ファイルを読み込めませんでした"
                restoreErrorMessage = error.localizedDescription
                showRestoreError = true
            }
        }
    }

    // MARK: - Sections

    private var displaySection: some View {
        VStack(spacing: 0) {
            sectionHeader("表示")
            settingsGroup {
                appearanceRow
                Divider().padding(.leading, 50)
                memoryNotificationRow
            }
        }
    }

    private var dataSection: some View {
        VStack(spacing: 0) {
            sectionHeader("データ")
            settingsGroup {
                backupExportRow
                Divider().padding(.leading, 50)
                backupImportRow
                Divider().padding(.leading, 50)
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
                Text("過去の同じ日の旅行をカードで表示")
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

    // MARK: - Appearance

    private var appearanceRow: some View {
        HStack(spacing: 10) {
            settingsIcon(icon: "circle.lefthalf.filled")
            Text("ダークモード")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.irohaSumi)
            Spacer()
            Picker("", selection: $appearanceMode) {
                Text("システム").tag(0)
                Text("ライト").tag(1)
                Text("ダーク").tag(2)
            }
            .pickerStyle(.menu)
            .tint(.irohaSumi3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.irohaSumi3)
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 5)
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.irohaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.irohaWashi3, lineWidth: 0.5))
        .padding(.horizontal, 14)
    }

    private func settingsRow(icon: String?, iconBg: (any ShapeStyle)?, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            if let icon, let bg = iconBg as? Color {
                settingsIcon(icon: icon, bg: bg)
            } else if let icon, iconBg != nil {
                settingsIcon(icon: icon)
            }
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.irohaSumi)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.irohaSumi3)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func settingsIcon(icon: String, bg: Color = .clear) -> some View {
        Image(systemName: icon)
            .font(.system(size: 15))
            .foregroundColor(.irohaSumi2)
            .frame(width: 26, height: 26)
    }

    private func settingsToggleRow(icon: String, iconBg: Color, label: String, key: String, defaultOn: Bool = true) -> some View {
        HStack(spacing: 10) {
            settingsIcon(icon: icon, bg: iconBg)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.irohaSumi)
            Spacer()
            Toggle("", isOn: Binding(
                get: { UserDefaults.standard.object(forKey: key) as? Bool ?? defaultOn },
                set: { UserDefaults.standard.set($0, forKey: key) }
            ))
            .labelsHidden()
            .tint(.irohaFuji)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - Backup

    private var backupExportRow: some View {
        Button {
            showBackupConfirmation = true
        } label: {
            HStack(spacing: 10) {
                settingsIcon(icon: "square.and.arrow.up", bg: .irohaFuji)
                VStack(alignment: .leading, spacing: 2) {
                    Text("バックアップを作成")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.irohaSumi)
                    if let dateLabel = lastBackupLabel {
                        Text("前回: \(dateLabel)")
                            .font(.system(size: 11))
                            .foregroundColor(.irohaSumi3)
                    }
                }
                Spacer()
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 14))
                    .foregroundColor(.irohaFuji)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .alert("バックアップを作成しますか？", isPresented: $showBackupConfirmation) {
            Button("作成") { exportBackup() }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("現在の旅行記録をJSON形式で書き出します。写真は含まれません。")
        }
    }

    private var backupImportRow: some View {
        Button {
            showImportPicker = true
        } label: {
            HStack(spacing: 10) {
                settingsIcon(icon: "square.and.arrow.down", bg: .irohaFuji)
                Text("バックアップから復元")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.irohaSumi)
                Spacer()
                Image(systemName: "doc.badge.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(.irohaSumi3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
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

    private func exportBackup() {
        do {
            let url = try BackupManager.export(prefectures: prefectures)
            lastBackupTimestamp = Date().timeIntervalSince1970

            guard
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = scene.keyWindow,
                let rootVC = window.rootViewController
            else { return }

            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let popover = controller.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(controller, animated: true)
        } catch {
            errorAlertTitle = "バックアップ作成に失敗しました"
            restoreErrorMessage = error.localizedDescription
            showRestoreError = true
        }
    }

    private func performRestore() {
        guard let url = pendingRestoreURL else { return }
        do {
            let count = try BackupManager.restore(from: url, prefectures: prefectures, context: modelContext)
            restoredCount = count
            showRestoreSuccess = true
        } catch {
            errorAlertTitle = "復元に失敗しました"
            restoreErrorMessage = error.localizedDescription
            showRestoreError = true
        }
        pendingRestoreURL = nil
    }

    private func resetApp() {
        resetAll()
        UserDefaults.standard.removeObject(forKey: "onboarding_done")
        UserDefaults.standard.removeObject(forKey: "appearance_mode")
        UserDefaults.standard.removeObject(forKey: "last_backup_date")
        UserDefaults.standard.removeObject(forKey: "show_memory_card")
        appearanceMode = 0
        lastBackupTimestamp = 0
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
