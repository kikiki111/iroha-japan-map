//
//  VisitStyleIDMigration.swift
//  Iroha
//

import Foundation
import SwiftData

/// 旧 `Visit.tag` (`VisitTag?`) の値を新 `Visit.styleID` (`String?`) へ転記する。
///
/// CloudKit の `CD_tag` が BYTES で確定しているため `tag` は enum のまま残し、
/// 正となるスタイル ID は STRING の `CD_styleID` に持たせる構成にした（経緯は
/// `VisitTag` のコメントを参照）。既存レコードと旧バージョン端末から降ってくる
/// レコードの双方を、起動時にこの移行で `styleID` 側へ寄せる。
///
/// - Note: 判定は UserDefaults のフラグに依存せず、データ自身の状態で都度スキャンする。
///   途中クラッシュでも次回起動で残作業が継続する。旧バージョン端末が `tag` だけを
///   埋めた新規レコードを CloudKit 経由で送ってきた場合も、次の起動で拾える。
/// - Note: 転記後も旧 `tag` は消さない。旧バージョンアプリ (1.0.5) は `styleID` を
///   知らず `tag` だけを見るため、消すと旧端末側でスタイルバッジが失われる。
///   スタイルを変更・解除したときだけ `Visit.setStyleID(_:)` がクリアする。
enum VisitStyleIDMigration {

    /// 起動時に一度だけ呼ぶ。`styleID` が未設定で旧 `tag` に値があるものだけを転記する。
    static func migrate(context: ModelContext) {
        // `styleID` は optional String、`tag` はエンコード済み属性として扱われるため
        // `#Predicate` での nil 評価が保証されない。`PhotoMigration` /
        // `VisitPrefectureMigration` と同様に全件 fetch + in-memory フィルタで検出する。
        guard let visits = try? context.fetch(FetchDescriptor<Visit>()) else { return }

        var didUpdate = false
        for visit in visits where !visit.isDeleted {
            guard visit.styleID == nil, let legacy = visit.tag else { continue }
            // 旧 `.none` は「未選択」の意味。`styleID` は nil で表すため転記しない
            // (書き込まないので毎起動スキャンに残るが、save は発生しない)。
            guard legacy != .none else { continue }
            visit.styleID = legacy.rawValue
            didUpdate = true
        }

        if didUpdate {
            try? context.save()
        }
    }
}
