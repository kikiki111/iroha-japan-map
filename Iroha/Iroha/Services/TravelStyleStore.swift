//
//  TravelStyleStore.swift
//  Iroha
//

import Foundation
import SwiftData

/// 旅行スタイル (`TravelStyleRecord`) の書き込みユーティリティ。
///
/// - Note: 読み取りは各 View の `@Query` + `TravelStyleCatalog` が担う。
///         本ストアは **書き込み専用**（`CompanionSuggestionStore` と同じ役割分担）。
/// - Note: プリセットは seed しない。非表示にするときだけオーバーレイ行を作る。
enum TravelStyleStore {

    // MARK: - カスタムスタイル

    @discardableResult
    static func addCustom(name: String,
                          palette: TravelStylePalette,
                          iconName: String,
                          existing: [TravelStyleRecord],
                          context: ModelContext) throws -> TravelStyleRecord {
        let nextOrder = (existing.filter { !$0.isPresetOverride }.map(\.sortOrder).max() ?? 0) + 1
        let record = TravelStyleRecord(
            presetKey: "",
            name: normalized(name),
            iconName: iconName,
            paletteKey: palette.rawValue,
            sortOrder: nextOrder
        )
        context.insert(record)
        try context.save()
        return record
    }

    static func updateCustom(_ record: TravelStyleRecord,
                             name: String,
                             palette: TravelStylePalette,
                             iconName: String,
                             context: ModelContext) throws {
        record.name       = normalized(name)
        record.paletteKey = palette.rawValue
        record.iconName   = iconName
        try context.save()
    }

    /// カスタムスタイルの表示・非表示を切り替える。
    ///
    /// 非表示にしても記録の `tag` は変えない（プリセットの非表示と同じ挙動）。
    /// 過去の記録に付いたバッジは残り、選択肢とフィルタからだけ消える。
    static func setCustomHidden(_ record: TravelStyleRecord,
                                hidden: Bool,
                                context: ModelContext) throws {
        record.isHidden = hidden
        try context.save()
    }

    /// 使用中の記録からスタイルを外したうえでレコードを削除する（1 トランザクション）。
    ///
    /// 記録そのものは削除しない。タグを nil にするだけ。
    static func deleteCustom(_ record: TravelStyleRecord,
                             detachFrom visits: [Visit],
                             context: ModelContext) throws {
        let styleID = record.styleID
        // 旧 `tag` 側にしか値がない未移行レコードも拾うため `effectiveStyleID` で判定し、
        // `setStyleID(nil)` で両方クリアする。旧 `tag` を残すとフォールバックで
        // 削除済みスタイルが復活する。
        for visit in visits where visit.effectiveStyleID == styleID {
            visit.setStyleID(nil)
        }
        context.delete(record)
        try context.save()
    }

    // MARK: - プリセットの非表示

    static func setPresetHidden(_ preset: TravelStylePreset,
                                hidden: Bool,
                                records: [TravelStyleRecord],
                                context: ModelContext) throws {
        let overlays = records.filter { $0.presetKey == preset.rawValue }
        if hidden {
            if overlays.isEmpty {
                context.insert(TravelStyleRecord(presetKey: preset.rawValue, isHidden: true))
            } else {
                for overlay in overlays { overlay.isHidden = true }
            }
        } else {
            // 冪等化: 複数端末で生まれた重複オーバーレイをまとめて掃除する
            for overlay in overlays { context.delete(overlay) }
        }
        try context.save()
    }

    // MARK: - 集計

    /// 指定スタイルを使っている記録数
    static func usageCount(styleID: String, in visits: [Visit]) -> Int {
        visits.filter { $0.effectiveStyleID == styleID }.count
    }

    // MARK: - 初期化

    /// 全レコードを破棄する（`SettingsView.resetApp()` 用）。
    /// `CompanionSuggestionStore.clear()` と対になる位置づけ。
    static func clear(context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<TravelStyleRecord>()) else { return }
        for record in all { context.delete(record) }
        try? context.save()
    }

    // MARK: - Helpers

    private static func normalized(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(TravelStyleLimit.maxNameLength))
    }
}
