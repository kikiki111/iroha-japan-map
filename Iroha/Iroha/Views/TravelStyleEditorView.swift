//
//  TravelStyleEditorView.swift
//  Iroha
//
//  ユーザー定義の旅行スタイルを追加・編集するシート

import SwiftUI
import SwiftData

struct TravelStyleEditorView: View {
    /// nil なら新規追加
    let record: TravelStyleRecord?
    let existingRecords: [TravelStyleRecord]
    /// 削除時に記録からスタイルを外すための全記録
    var visits: [Visit] = []

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var palette: TravelStylePalette = TravelStylePalette.fallback
    @State private var iconName: String = TravelStyleIcon.fallback
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var showDeleteConfirmation = false

    private var isEditing: Bool { record != nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { !trimmedName.isEmpty }

    /// プレビュー用。保存前の見た目をそのまま確認できる。
    private var previewStyle: TravelStyle {
        TravelStyle(
            id: record?.styleID ?? "preview",
            name: trimmedName.isEmpty ? "スタイル名" : trimmedName,
            iconName: iconName,
            palette: palette,
            isPreset: false,
            isLegacy: false
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                previewSection
                nameSection
                colorSection
                iconSection
                if record != nil {
                    deleteSection
                }
            }
            .padding(.bottom, Metrics.bottomPadding)
        }
        .background(Color.irohaWashi)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isEditing ? "スタイルを編集" : "スタイルを追加")
                    .font(.system(size: Metrics.titleSize, weight: .light, design: .serif))
                    .tracking(1)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
                    .foregroundColor(.irohaSumi2)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .alert("保存できませんでした", isPresented: $showSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
        .alert("「\(record?.name ?? "")」を削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) { performDelete() }
        } message: {
            Text(deletionMessage)
        }
        .onAppear(perform: loadIfNeeded)
    }

    // MARK: - Sections

    private var previewSection: some View {
        VStack(spacing: Metrics.previewSpacing) {
            HStack(spacing: 6) {
                Image(systemName: previewStyle.iconName)
                    .font(.system(size: 13))
                Text(previewStyle.name)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundColor(previewStyle.foregroundColor)
            .padding(.horizontal, Metrics.previewHPadding)
            .padding(.vertical, Metrics.previewVPadding)
            .background(previewStyle.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.previewCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.previewCornerRadius)
                    .stroke(previewStyle.foregroundColor.opacity(0.3), lineWidth: 0.5)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Metrics.previewSectionVPadding)
    }

    private var nameSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader("名前")
            SettingsGroup {
                HStack(spacing: Metrics.rowSpacing) {
                    TextField("例: 出張", text: $name)
                        .font(.system(size: Metrics.fieldSize))
                        .textInputAutocapitalization(.never)
                        .onChange(of: name) { _, newValue in
                            // 上限を超えた入力はその場で切り詰める
                            if newValue.count > TravelStyleLimit.maxNameLength {
                                name = String(newValue.prefix(TravelStyleLimit.maxNameLength))
                            }
                        }
                    Text("\(trimmedName.count)/\(TravelStyleLimit.maxNameLength)")
                        .font(.system(size: Metrics.counterSize))
                        .foregroundColor(.irohaSumi3)
                        .monospacedDigit()
                }
                .padding(.horizontal, Metrics.rowHPadding)
                .padding(.vertical, Metrics.rowVPadding)
            }
        }
    }

    private var colorSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader("色")
            SettingsGroup {
                LazyVGrid(columns: gridColumns(count: Metrics.colorColumns), spacing: Metrics.gridSpacing) {
                    ForEach(TravelStylePalette.userSelectable, id: \.rawValue) { candidate in
                        colorSwatch(candidate)
                    }
                }
                .padding(.horizontal, Metrics.rowHPadding)
                .padding(.vertical, Metrics.gridVPadding)
            }
        }
    }

    private var iconSection: some View {
        VStack(spacing: 0) {
            SettingsSectionHeader("アイコン")
            SettingsGroup {
                LazyVGrid(columns: gridColumns(count: Metrics.iconColumns), spacing: Metrics.gridSpacing) {
                    ForEach(TravelStyleIcon.selectable, id: \.self) { candidate in
                        iconSwatch(candidate)
                    }
                }
                .padding(.horizontal, Metrics.rowHPadding)
                .padding(.vertical, Metrics.gridVPadding)
            }
        }
    }

    private var deleteSection: some View {
        VStack(spacing: 0) {
            Button("このスタイルを削除", role: .destructive) {
                showDeleteConfirmation = true
            }
            .font(.system(size: Metrics.deleteFontSize))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Metrics.deleteVPadding)

            SettingsFootnote(
                "一時的に隠したいだけなら、一覧のスイッチで非表示にできます。"
            )
        }
        .padding(.top, Metrics.deleteTopPadding)
    }

    private var deletionMessage: String {
        guard let record else { return "この操作は元に戻せません。" }
        let count = TravelStyleStore.usageCount(styleID: record.styleID, in: visits)
        guard count > 0 else { return "この操作は元に戻せません。" }
        return "\(count)件の記録からこのスタイルが外れます。記録そのものは削除されません。"
    }

    // MARK: - Swatches

    private func colorSwatch(_ candidate: TravelStylePalette) -> some View {
        let isSelected = palette == candidate
        return Button {
            palette = candidate
        } label: {
            VStack(spacing: Metrics.swatchTextSpacing) {
                Circle()
                    .fill(candidate.backgroundColor)
                    .overlay(Circle().stroke(candidate.foregroundColor, lineWidth: isSelected ? 2 : 0.5))
                    .frame(width: Metrics.swatchSize, height: Metrics.swatchSize)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: Metrics.checkSize, weight: .bold))
                                .foregroundColor(candidate.foregroundColor)
                        }
                    }
                Text(candidate.displayName)
                    .font(.system(size: Metrics.swatchLabelSize))
                    .foregroundColor(isSelected ? .irohaSumi : .irohaSumi3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(candidate.displayName)
    }

    private func iconSwatch(_ candidate: String) -> some View {
        let isSelected = iconName == candidate
        return Button {
            iconName = candidate
        } label: {
            Image(systemName: candidate)
                .font(.system(size: Metrics.iconSwatchFontSize))
                .foregroundColor(isSelected ? palette.foregroundColor : .irohaSumi3)
                .frame(maxWidth: .infinity, minHeight: Metrics.iconSwatchHeight)
                .background(isSelected ? palette.backgroundColor : Color.irohaWashi2)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.iconSwatchCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.iconSwatchCornerRadius)
                        .stroke(isSelected ? palette.foregroundColor.opacity(0.4) : Color.irohaWashi3,
                                lineWidth: 0.5)
                )
        }
        .accessibilityLabel(candidate)
    }

    private func gridColumns(count: Int) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Metrics.gridSpacing), count: count)
    }

    // MARK: - Actions

    private func loadIfNeeded() {
        guard let record else { return }
        name = record.name
        palette = record.palette
        iconName = TravelStyleIcon.resolved(record.iconName)
    }

    private func performDelete() {
        guard let record else { return }
        do {
            try TravelStyleStore.deleteCustom(record, detachFrom: visits, context: modelContext)
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private func save() {
        guard canSave else { return }
        do {
            if let record {
                try TravelStyleStore.updateCustom(
                    record,
                    name: trimmedName,
                    palette: palette,
                    iconName: iconName,
                    context: modelContext
                )
            } else {
                try TravelStyleStore.addCustom(
                    name: trimmedName,
                    palette: palette,
                    iconName: iconName,
                    existing: existingRecords,
                    context: modelContext
                )
            }
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private enum Metrics {
        static let titleSize: CGFloat = 18
        static let bottomPadding: CGFloat = 24

        static let previewSpacing: CGFloat = 8
        static let previewHPadding: CGFloat = 16
        static let previewVPadding: CGFloat = 10
        static let previewCornerRadius: CGFloat = 10
        static let previewSectionVPadding: CGFloat = 20

        static let rowSpacing: CGFloat = 10
        static let rowHPadding: CGFloat = 14
        static let rowVPadding: CGFloat = 10
        static let fieldSize: CGFloat = 15
        static let counterSize: CGFloat = 12

        static let colorColumns = 4
        static let iconColumns = 6
        static let gridSpacing: CGFloat = 8
        static let gridVPadding: CGFloat = 12

        static let swatchSize: CGFloat = 34
        static let swatchTextSpacing: CGFloat = 3
        static let swatchLabelSize: CGFloat = 10
        static let checkSize: CGFloat = 12

        static let iconSwatchFontSize: CGFloat = 17
        static let iconSwatchHeight: CGFloat = 40
        static let iconSwatchCornerRadius: CGFloat = 8

        static let deleteFontSize: CGFloat = 15
        static let deleteVPadding: CGFloat = 12
        static let deleteTopPadding: CGFloat = 8
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TravelStyleEditorView(record: nil, existingRecords: [])
    }
    .modelContainer(for: [Visit.self, TravelStyleRecord.self], inMemory: true)
}
