//
//  TravelStyleSettingsView.swift
//  Iroha
//
//  旅行スタイルの管理画面（設定のサブ画面）

import SwiftUI
import SwiftData

struct TravelStyleSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [TravelStyleRecord]
    @Query private var visits: [Visit]

    @State private var editorTarget: EditorTarget?
    @State private var pendingDeletion: TravelStyleRecord?
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    private enum EditorTarget: Identifiable {
        case new
        case existing(TravelStyleRecord)

        var id: String {
            switch self {
            case .new:                return "new"
            case .existing(let rec):  return rec.id.uuidString
            }
        }
    }

    private var hiddenPresetKeys: Set<String> {
        Set(records.filter { $0.isPresetOverride && $0.isHidden }.map(\.presetKey))
    }

    private var customRecords: [TravelStyleRecord] {
        records
            .filter { !$0.isPresetOverride }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    private var canAddMore: Bool { customRecords.count < TravelStyleLimit.maxCustomCount }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                presetSection
                customSection
            }
            .padding(.bottom, Metrics.bottomPadding)
        }
        .background(Color.irohaWashi)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("旅行スタイル")
                    .font(.system(size: Metrics.titleSize, weight: .light, design: .serif))
                    .tracking(1)
            }
        }
        .sheet(item: $editorTarget) { target in
            NavigationStack {
                TravelStyleEditorView(
                    record: {
                        if case .existing(let rec) = target { return rec }
                        return nil
                    }(),
                    existingRecords: records,
                    visits: visits
                )
            }
            .presentationDetents([.large])
            .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .alert(
            "「\(pendingDeletion?.name ?? "")」を削除しますか？",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { record in
            Button("キャンセル", role: .cancel) { pendingDeletion = nil }
            Button("削除", role: .destructive) { performDelete(record) }
        } message: { record in
            Text(deletionMessage(for: record))
        }
        .alert("保存できませんでした", isPresented: $showSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    // MARK: - Preset section

    private var presetSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader("プリセット")
            SettingsGroup {
                ForEach(Array(TravelStylePreset.selectable.enumerated()), id: \.element.rawValue) { index, preset in
                    if index > 0 {
                        SettingsDivider()
                    }
                    presetRow(preset)
                }
            }
            SettingsFootnote(
                "プリセットの名前・色・アイコンは変更できません。非表示にしても、過去の記録に付いたスタイルはそのまま残ります。"
            )
        }
    }

    private func presetRow(_ preset: TravelStylePreset) -> some View {
        let style = preset.style
        let isHidden = hiddenPresetKeys.contains(preset.rawValue)
        let count = TravelStyleStore.usageCount(styleID: preset.rawValue, in: visits)

        return HStack(spacing: Metrics.rowSpacing) {
            styleChip(style)
            Spacer()
            usageLabel(count)
            Toggle("", isOn: Binding(
                get: { !isHidden },
                set: { setPresetHidden(preset, hidden: !$0) }
            ))
            .labelsHidden()
            .tint(.irohaFuji)
        }
        .padding(.horizontal, Metrics.rowHPadding)
        .padding(.vertical, Metrics.rowVPadding)
        .opacity(isHidden ? Metrics.hiddenOpacity : 1)
    }

    // MARK: - Custom section

    private var customSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader("自分のスタイル")
            SettingsGroup {
                if customRecords.isEmpty {
                    emptyCustomRow
                    SettingsDivider(leading: SettingsMetrics.dividerLeadingWithoutIcon)
                } else {
                    ForEach(customRecords) { record in
                        customRow(record)
                        SettingsDivider(leading: SettingsMetrics.dividerLeadingWithoutIcon)
                    }
                }
                addRow
            }
            SettingsFootnote(
                canAddMore
                    ? "スイッチで表示・非表示を切り替えられます。削除は名前をタップして編集画面から行います。最大 \(TravelStyleLimit.maxCustomCount) 件まで追加できます。"
                    : "スイッチで表示・非表示を切り替えられます。削除は名前をタップして編集画面から行います。追加できるのは \(TravelStyleLimit.maxCustomCount) 件までです。"
            )
        }
    }

    private var emptyCustomRow: some View {
        Text("まだありません")
            .font(.system(size: Metrics.emptySize))
            .foregroundColor(.irohaSumi3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metrics.rowHPadding)
            .padding(.vertical, Metrics.rowVPadding)
    }

    private func customRow(_ record: TravelStyleRecord) -> some View {
        let count = TravelStyleStore.usageCount(styleID: record.styleID, in: visits)

        return HStack(spacing: Metrics.rowSpacing) {
            // チップ側をタップで編集シートへ。トグルと当たり判定を分けるため
            // 行全体を Button にはしない。
            Button {
                editorTarget = .existing(record)
            } label: {
                HStack(spacing: Metrics.rowSpacing) {
                    if let style = record.customStyle {
                        styleChip(style)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: Metrics.chevronSize, weight: .semibold))
                        .foregroundColor(.irohaSumi3)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            usageLabel(count)
            Toggle("", isOn: Binding(
                get: { !record.isHidden },
                set: { setCustomHidden(record, hidden: !$0) }
            ))
            .labelsHidden()
            .tint(.irohaFuji)
        }
        .padding(.horizontal, Metrics.rowHPadding)
        .padding(.vertical, Metrics.rowVPadding)
        .opacity(record.isHidden ? Metrics.hiddenOpacity : 1)
        .contextMenu {
            Button(role: .destructive) {
                pendingDeletion = record
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private var addRow: some View {
        Button {
            editorTarget = .new
        } label: {
            HStack(spacing: Metrics.rowSpacing) {
                Image(systemName: "plus.circle")
                    .font(.system(size: Metrics.addIconSize))
                    .foregroundColor(canAddMore ? .irohaFujiDk : .irohaSumi3)
                Text("スタイルを追加")
                    .font(.system(size: Metrics.labelSize, weight: .medium))
                    .foregroundColor(canAddMore ? .irohaFujiDk : .irohaSumi3)
                Spacer()
            }
            .padding(.horizontal, Metrics.rowHPadding)
            .padding(.vertical, Metrics.rowVPadding)
        }
        .disabled(!canAddMore)
    }

    // MARK: - Shared parts

    private func styleChip(_ style: TravelStyle) -> some View {
        HStack(spacing: Metrics.chipSpacing) {
            Image(systemName: style.iconName)
                .font(.system(size: Metrics.chipIconSize))
            Text(style.name)
                .font(.system(size: Metrics.chipLabelSize, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(style.foregroundColor)
        .padding(.horizontal, Metrics.chipHPadding)
        .padding(.vertical, Metrics.chipVPadding)
        .background(style.backgroundColor)
        .clipShape(Capsule())
    }

    private func usageLabel(_ count: Int) -> some View {
        Text("\(count)件")
            .font(.system(size: Metrics.usageSize))
            .foregroundColor(.irohaSumi3)
            .monospacedDigit()
    }

    private func deletionMessage(for record: TravelStyleRecord) -> String {
        let count = TravelStyleStore.usageCount(styleID: record.styleID, in: visits)
        guard count > 0 else {
            return "この操作は元に戻せません。"
        }
        return "\(count)件の記録からこのスタイルが外れます。記録そのものは削除されません。"
    }

    // MARK: - Actions

    private func setPresetHidden(_ preset: TravelStylePreset, hidden: Bool) {
        do {
            try TravelStyleStore.setPresetHidden(
                preset,
                hidden: hidden,
                records: records,
                context: modelContext
            )
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private func setCustomHidden(_ record: TravelStyleRecord, hidden: Bool) {
        do {
            try TravelStyleStore.setCustomHidden(record, hidden: hidden, context: modelContext)
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private func performDelete(_ record: TravelStyleRecord) {
        do {
            try TravelStyleStore.deleteCustom(
                record,
                detachFrom: visits,
                context: modelContext
            )
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
        pendingDeletion = nil
    }

    private enum Metrics {
        static let titleSize: CGFloat = 18
        static let bottomPadding: CGFloat = 24

        static let rowSpacing: CGFloat = 10
        static let rowHPadding: CGFloat = 14
        static let rowVPadding: CGFloat = 8
        static let labelSize: CGFloat = 15
        static let emptySize: CGFloat = 14
        static let usageSize: CGFloat = 12
        static let chevronSize: CGFloat = 12
        static let addIconSize: CGFloat = 17
        static let hiddenOpacity: Double = 0.45

        static let chipSpacing: CGFloat = 5
        static let chipIconSize: CGFloat = 12
        static let chipLabelSize: CGFloat = 13
        static let chipHPadding: CGFloat = 10
        static let chipVPadding: CGFloat = 4
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TravelStyleSettingsView()
    }
    .modelContainer(for: [Visit.self, TravelStyleRecord.self], inMemory: true)
}
