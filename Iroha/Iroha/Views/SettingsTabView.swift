//
//  SettingsView.swift
//  Iroha
//
//  プロフィールから push 遷移する設定画面

import SwiftUI
import SwiftData

/// 設定画面（プロフィールからpush遷移）
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [Visit]
    @Query private var prefectures: [Prefecture]

    @AppStorage("appearance_mode") private var appearanceMode: Int = 0
    @State private var showResetConfirmation = false
    @State private var showResetFinalConfirmation = false

    private var appearanceLabel: String {
        switch appearanceMode {
        case 1: return "ライト"
        case 2: return "ダーク"
        default: return "システム連動"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 表示
                sectionHeader("表示")
                settingsGroup {
                    appearanceRow
                }

                // 通知
                sectionHeader("通知")
                settingsGroup {
                    memoryNotificationRow
                }

                // データ
                sectionHeader("データ")
                settingsGroup {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 10) {
                            settingsIcon(icon: "\u{FF01}", bg: Color(hex: "#E05555"))
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
                }

                // Iroha について
                sectionHeader("Iroha について")
                settingsGroup {
                    settingsRow(icon: nil, iconBg: nil, label: "バージョン", value: "1.1.0")
                }
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
            Button("リセットする", role: .destructive) {
                showResetFinalConfirmation = true
            }
        } message: {
            Text("この操作は元に戻せません。")
        }
        .alert("すべてのデータを削除します", isPresented: $showResetFinalConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("すべてをリセット", role: .destructive) {
                resetAll()
            }
        } message: {
            Text("すべての訪問記録・写真・マイルストーンが削除されます。")
        }
    }

    // MARK: - Memory notification

    private var memoryNotificationRow: some View {
        HStack(spacing: 10) {
            settingsIcon(icon: "\u{25C8}", bg: Color.irohaFujiDk)
            VStack(alignment: .leading, spacing: 2) {
                Text("今日の記憶")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.irohaSumi)
                Text("過去の同じ日の訪問を通知")
                    .font(.system(size: 11))
                    .foregroundColor(.irohaSumi3)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { UserDefaults.standard.object(forKey: "notify_memory") as? Bool ?? true },
                set: { newValue in
                    UserDefaults.standard.set(newValue, forKey: "notify_memory")
                    MemoryNotificationManager.reschedule(visits: visits)
                }
            ))
            .labelsHidden()
            .tint(.irohaFuji)
            .scaleEffect(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - Appearance

    private var appearanceRow: some View {
        HStack(spacing: 10) {
            Text("\u{25D1}")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(
                    LinearGradient(colors: [Color.irohaSumi2, Color.irohaSumi],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
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
            } else if let icon, let bg = iconBg as? LinearGradient {
                Text(icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(bg)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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

    private func settingsIcon(icon: String, bg: Color) -> some View {
        Text(icon)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .frame(width: 26, height: 26)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
            .scaleEffect(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    // MARK: - Actions

    private func resetAll() {
        for visit in visits {
            if let filename = visit.photoFilename {
                PhotoStorageManager.delete(filename: filename)
            }
            modelContext.delete(visit)
        }
        UserDefaults.standard.removeObject(forKey: "milestone_25_shown")
        UserDefaults.standard.removeObject(forKey: "milestone_47_shown")
        for region in Region.allCases {
            UserDefaults.standard.removeObject(forKey: "region_\(region.rawValue)_shown")
        }
        for pref in prefectures {
            pref.isBookmarked = false
            pref.isWanted = false
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
