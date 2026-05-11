//
//  VisitPrefectureMigration.swift
//  Iroha
//

import Foundation
import SwiftData

/// 既存 `Visit` レコードの `prefectureID` を `prefectureName` から backfill する。
///
/// `Prefecture` を SwiftData モデルから外して static struct 化したため、
/// 旧バージョンで保存された `Visit` の `prefectureID` は default 値 0 のまま。
/// これを正しい `Prefecture.id` に埋めないと、`VisitStats` などの prefectureID
/// ベースの絞り込みで過去の記録が見えなくなる。
///
/// - Note: 判定は UserDefaults のフラグに依存せず、`prefectureID == 0` の Visit が
///   存在するかで都度スキャンする。途中クラッシュでも次回起動で残作業が継続する。
enum VisitPrefectureMigration {

    /// 起動時に一度だけ呼ぶ。`prefectureID == 0` の Visit を検出して backfill する。
    static func migrate(context: ModelContext) {
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
}
