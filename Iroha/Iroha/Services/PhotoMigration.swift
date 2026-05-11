//
//  PhotoMigration.swift
//  Iroha
//

import Foundation
import SwiftData
import UIKit

/// 旧 `Documents/Photos/{UUID}.jpg` + `Visit.photoFilenames` で保持されていた写真を、
/// 新 `VisitPhoto` モデル (CloudKit 同期対象) に転記する。
///
/// 設計方針 (Phase A: 旧データ保持版):
/// - **写真単位の冪等性**: `VisitPhoto.legacyFilename` を重複検出キーに使い、
///   既に転記済みの写真は再処理しない。これにより 5 枚中 3 枚処理してクラッシュ
///   しても、次回起動で残 2 枚から続行できる。
/// - **判定はスキャンベース**: UserDefaults フラグに依存せず、`allPhotoFilenames`
///   と `photos` の `legacyFilename` を毎回突合して未処理を検出する。
///   フラグ未設定 (bool default false) で migration が走らない罠を回避。
/// - **旧データは削除しない**: `Documents/Photos/` のファイルと `Visit` のレガシー
///   プロパティはそのまま保持する。CloudKit 同期成功確認後、別リリース (Phase B)
///   でクリーンアップする。
enum PhotoMigration {

    /// 起動時に呼ぶ。未処理の legacy 写真を検出し、`VisitPhoto` として転記する。
    static func migrate(context: ModelContext) {
        let descriptor = FetchDescriptor<Visit>()
        guard let visits = try? context.fetch(descriptor) else { return }

        var didUpdate = false
        for visit in visits where !visit.isDeleted {
            let migratedNames = Set((visit.photos ?? []).compactMap(\.legacyFilename))
            let unmigrated = visit.allPhotoFilenames.filter { !migratedNames.contains($0) }
            guard !unmigrated.isEmpty else { continue }

            for filename in unmigrated {
                guard let data = LegacyPhotoFileLoader.loadData(filename: filename) else {
                    // ファイルが見つからない (削除済み等) → スキップ。
                    // legacy 側のファイル名は残るが、新側は空のまま。
                    continue
                }
                _ = VisitPhotoStore.appendFromLegacyFileData(
                    data,
                    legacyFilename: filename,
                    to: visit,
                    in: context
                )
                didUpdate = true

                // 1 枚ごとに save してクラッシュ耐性を確保。
                // 失敗してもループは続行し、次回起動で残作業を再試行できる。
                try? context.save()
            }
        }

        if didUpdate {
            try? context.save()
        }
    }
}

/// 旧 `Documents/Photos/` から `Data` を読み込むヘルパー。
/// `PhotoStorageManager` (削除予定) の機能を限定的に複製。
private enum LegacyPhotoFileLoader {
    static func loadData(filename: String) -> Data? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("Photos", isDirectory: true)
            .appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }
}
