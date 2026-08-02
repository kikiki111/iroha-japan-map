//
//  TravelStyleCatalog.swift
//  Iroha
//
//  プリセットとユーザー定義を統合した旅行スタイルの参照テーブル

import SwiftUI
import SwiftData

/// プリセット + ユーザー定義を統合した参照テーブル。
///
/// `VisitStats` と同様、View 階層で 1 度作ってサブビューへ配る（Environment 経由）。
struct TravelStyleCatalog {
    /// ピッカー・フィルタに出す表示順（非表示・レガシーを除外済み）
    let selectable: [TravelStyle]
    /// カスタムのみ（設定画面の「自分のスタイル」用。非表示のものも含む）
    let customs: [TravelStyle]
    /// 非表示にされているプリセットの key
    let hiddenPresetKeys: Set<String>
    /// 非表示にされているカスタムスタイルの ID
    let hiddenCustomIDs: Set<String>

    /// 表示解決用。非表示プリセットとレガシーも含む全件を持つ。
    private let byID: [String: TravelStyle]

    init(records: [TravelStyleRecord]) {
        // 非表示プリセットを OR で畳む（複数端末で重複した行はここで吸収される）
        let hidden = Set(
            records.filter { $0.isPresetOverride && $0.isHidden }.map(\.presetKey)
        )
        self.hiddenPresetKeys = hidden

        // プリセットはレガシー込みで全件を解決テーブルへ入れる
        var table: [String: TravelStyle] = [:]
        for preset in TravelStylePreset.allCases {
            table[preset.rawValue] = preset.style
        }

        // カスタムは sortOrder → createdAt → id の順で決定的に並べる
        let customRecords = records
            .filter { !$0.isPresetOverride }
            .sorted { lhs, rhs in
                if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
        let customStyles = customRecords.compactMap(\.customStyle)
        for style in customStyles { table[style.id] = style }

        // 非表示カスタムもプリセットと同じ扱い: 選択肢から外すが、表示解決はできる
        let hiddenCustoms = Set(customRecords.filter(\.isHidden).map(\.styleID))
        self.hiddenCustomIDs = hiddenCustoms

        self.byID = table
        self.customs = customStyles
        self.selectable =
            TravelStylePreset.selectable
                .filter { !hidden.contains($0.rawValue) }
                .map(\.style)
            + customStyles.filter { !hiddenCustoms.contains($0.id) }
    }

    /// `Visit.tag` の生値からスタイルを解決する。
    ///
    /// 未選択 (`nil` / `"none"`) と未知 ID（他端末で削除済み等）は nil を返す。
    /// 非表示プリセットとレガシーは**解決できる**。過去の記録の表示を壊さないため。
    func style(for rawTag: String?) -> TravelStyle? {
        guard let rawTag, rawTag != TravelStyleID.noneSentinel else { return nil }
        return byID[rawTag]
    }

    func style(for visit: Visit) -> TravelStyle? {
        style(for: visit.effectiveStyleID)
    }

    /// 編集中の記録が非表示のスタイル（プリセット・カスタムどちらも）を使っている場合に、
    /// そのスタイルだけ選択肢へ足す。保存し直しただけでスタイルが外れるのを防ぐ。
    func selectableIncluding(_ current: TravelStyle?) -> [TravelStyle] {
        guard let current, !selectable.contains(current) else { return selectable }
        return selectable + [current]
    }
}

// MARK: - Environment

private struct TravelStyleCatalogKey: EnvironmentKey {
    static let defaultValue = TravelStyleCatalog(records: [])
}

extension EnvironmentValues {
    var travelStyleCatalog: TravelStyleCatalog {
        get { self[TravelStyleCatalogKey.self] }
        set { self[TravelStyleCatalogKey.self] = newValue }
    }
}

/// `@Query` の単一オーナー。カタログを構築して配下へ配る。
///
/// `@Query` を使うことで、ローカル保存だけでなく CloudKit のリモート反映も
/// SwiftUI の無効化に自動で載る。
struct TravelStyleCatalogProvider<Content: View>: View {
    @Query private var records: [TravelStyleRecord]
    @ViewBuilder var content: Content

    var body: some View {
        content.environment(\.travelStyleCatalog, TravelStyleCatalog(records: records))
    }
}
