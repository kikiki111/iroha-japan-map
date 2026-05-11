//
//  CloudSyncOnboardingView.swift
//  Iroha
//

import SwiftUI

/// アプリ初回起動時に iCloud 同期について通知するシート (案 E: デフォルト ON 化)。
///
/// `cloud_sync_enabled` は default true として扱われており、ModelContainer は
/// 起動時から CloudKit 同期有効で構築されている。本シートは「同期が ON である」
/// ことの通知と、OFF 切替の選択肢を提供する。
///
/// - 「OK」を選んだ場合: そのまま使い始める (既に同期中)
/// - 「同期を OFF にする」を選んだ場合: cloud_sync_enabled = false 保存 +
///   「次回起動時から OFF」の案内 (アプリ再起動が必要)
///
/// `cloud_sync_onboarding_done` フラグで 1 度だけ表示する。
struct CloudSyncOnboardingView: View {
    @AppStorage(CloudSyncStatusObserver.syncEnabledKey) private var syncEnabled: Bool = true
    @AppStorage("cloud_sync_onboarding_done") private var onboardingDone: Bool = false
    @Environment(\.dismiss) private var dismiss

    @State private var showOptOutConfirmation = false
    @State private var showOptOutRestartNotice = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.icloud")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(Color(hex: "#5A8F7B"))

            VStack(spacing: 8) {
                Text("旅の記録は iCloud に自動保存されます")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(.irohaSumi)
                    .multilineTextAlignment(.center)
                    .tracking(1)

                Text("写真を含むすべての記録が自動的に iCloud に保存され、機種変更や再インストール後もサインインだけで復元されます。")
                    .font(.system(size: 13))
                    .foregroundColor(.irohaSumi2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                row(icon: "checkmark.circle.fill", text: "Apple ID にサインイン中の端末で自動同期")
                row(icon: "checkmark.circle.fill", text: "アプリを削除しても復元可能")
                row(icon: "checkmark.circle.fill", text: "複数端末 (iPhone/iPad) で同じデータ")
                row(icon: "info.circle.fill", text: "iCloud の容量を使用します", isInfo: true)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    syncEnabled = true
                    onboardingDone = true
                    dismiss()
                } label: {
                    Text("OK")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.irohaFujiDk)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showOptOutConfirmation = true
                } label: {
                    Text("同期を OFF にする")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.irohaSumi3)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)

            Text("いつでも設定から変更できます。")
                .font(.system(size: 11))
                .foregroundColor(.irohaSumi3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color.irohaWashi)
        .interactiveDismissDisabled()
        .alert("iCloud 同期を OFF にしますか?", isPresented: $showOptOutConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("OFF にする", role: .destructive) {
                syncEnabled = false
                showOptOutRestartNotice = true
            }
        } message: {
            Text("OFF にすると、写真と記録は端末内のみに保存されます。アプリを削除すると失われます。設定でいつでも ON に戻せます。")
        }
        .alert("次回起動時から反映されます", isPresented: $showOptOutRestartNotice) {
            Button("OK") {
                onboardingDone = true
                dismiss()
            }
        } message: {
            Text("iCloud 同期 OFF の設定を反映するには、アプリを完全に終了して再起動してください。")
        }
    }

    private func row(icon: String, text: String, isInfo: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(isInfo ? .irohaSumi3 : Color(hex: "#5A8F7B"))
                .frame(width: 16)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.irohaSumi2)
            Spacer()
        }
    }
}

#Preview {
    CloudSyncOnboardingView()
}
