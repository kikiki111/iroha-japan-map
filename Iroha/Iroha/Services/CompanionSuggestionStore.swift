//
//  CompanionSuggestionStore.swift
//  Iroha
//

import Foundation

/// 同行者サジェストの「非表示リスト」を UserDefaults で管理するユーティリティ
///
/// - Note: 同行者マスタは存在せず、候補は保存済み `Visit.companions` から毎回抽出される。
///         本ストアは **候補表示の抑制のみ** を担い、記録側 (`Visit.companions`) には一切触れない。
///         非表示にした名前を手入力で追加し直すと `unhide` で解除される想定。
/// - Note: 端末ローカル設定として扱い、iCloud 同期の対象外とする (`appearance_mode` 等と同じ)。
enum CompanionSuggestionStore {
    /// UserDefaults キー: 候補から非表示にした同行者名の配列
    static let hiddenKey = "hidden_companion_suggestions"

    /// 非表示にしている同行者名を返す
    static func hidden() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: hiddenKey) ?? [])
    }

    /// 指定した名前を候補から非表示にする
    static func hide(_ name: String) {
        var names = hidden()
        names.insert(name)
        save(names)
    }

    /// 指定した名前の非表示を解除する
    static func unhide(_ name: String) {
        var names = hidden()
        guard names.remove(name) != nil else { return }
        save(names)
    }

    /// 非表示リストをすべて破棄する (アプリ初期化用)
    static func clear() {
        UserDefaults.standard.removeObject(forKey: hiddenKey)
    }

    private static func save(_ names: Set<String>) {
        UserDefaults.standard.set(Array(names).sorted(), forKey: hiddenKey)
    }
}
