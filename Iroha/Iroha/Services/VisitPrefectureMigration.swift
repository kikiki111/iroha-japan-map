//
//  VisitPrefectureMigration.swift
//  Iroha
//

import Foundation
import SwiftData

/// 既存 `Visit` レコードの都道府県フィールドを最新スキーマに揃える。
///
/// 2 フェーズ構成:
/// 1. `prefectureID` の backfill — `Prefecture` を SwiftData モデルから外して static
///    struct 化したため、旧バージョンで保存された `Visit` の `prefectureID` は default
///    値 0 のまま。正しい `Prefecture.id` に埋めないと `VisitStats` などの prefectureID
///    ベースの絞り込みで過去の記録が見えなくなる。
/// 2. `prefectureIDs` の seed — 複数県対応で追加した配列を、単数 `prefectureID` から
///    詰め替える。あわせて旧バージョンアプリが CloudKit 経由で訪問先を変更した際に
///    生じるミラー不整合を修復する。
///
/// - Note: 判定は UserDefaults のフラグに依存せず、データ自身の状態で都度スキャンする。
///   途中クラッシュでも次回起動で残作業が継続する。
enum VisitPrefectureMigration {

    /// 起動時に一度だけ呼ぶ。フェーズ 1 → 2 の順に実行する
    /// (配列の seed は `prefectureID` の backfill 完了が前提)。
    static func migrate(context: ModelContext) {
        backfillPrefectureID(context: context)
        seedPrefectureIDs(context: context)
    }

    /// Phase 1: `prefectureID == 0` の Visit を `prefectureName` から backfill する。
    private static func backfillPrefectureID(context: ModelContext) {
        let descriptor = FetchDescriptor<Visit>(
            predicate: #Predicate { $0.prefectureID == 0 }
        )
        guard let pendingVisits = try? context.fetch(descriptor),
              !pendingVisits.isEmpty else {
            return
        }

        var didUpdate = false
        for visit in pendingVisits {
            guard let id = Prefecture.by(name: visit.prefectureName)?.id else {
                // 名前不一致 (旧データの異表記など) → スキップ。次回以降も再試行されるが、
                // 該当 Visit は集計対象外のままになる。
                continue
            }
            visit.prefectureID = id
            didUpdate = true
        }

        if didUpdate {
            try? context.save()
        }
    }

    /// Phase 2: `prefectureIDs` の seed と、先頭県ミラーの整合修復。
    ///
    /// - Note: `prefectureIDs` は SwiftData 上でエンコード済み属性として扱われ、
    ///   `#Predicate` での `isEmpty` 評価が保証されない。`PhotoMigration` と同様に
    ///   全件 fetch + in-memory フィルタで未処理を検出する。
    private static func seedPrefectureIDs(context: ModelContext) {
        guard let visits = try? context.fetch(FetchDescriptor<Visit>()) else { return }

        var didUpdate = false
        for visit in visits where !visit.isDeleted {
            // backfill できなかった (ID 未解決の) レコードは配列にも入れない
            guard visit.prefectureID != 0 else { continue }

            if visit.prefectureIDs.isEmpty {
                // 旧レコード、または旧バージョン端末から CloudKit 経由で来た新規レコード
                visit.prefectureIDs = [visit.prefectureID]
                didUpdate = true
            } else if visit.prefectureIDs.count == 1,
                      visit.prefectureIDs[0] != visit.prefectureID {
                // 旧バージョンアプリが訪問先を変更した単一県レコード。旧アプリは
                // `prefectureIDs` を知らないため配列だけ取り残される。単一県のときに
                // 限り旧フィールド側を正として再 seed する
                // (複数県レコードは旧アプリの意図を復元できないため配列側を温存)。
                visit.prefectureIDs = [visit.prefectureID]
                didUpdate = true
            }
        }

        if didUpdate {
            try? context.save()
        }
    }
}
