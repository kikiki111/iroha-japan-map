//
//  VisitPhoto.swift
//  Iroha
//

import Foundation
import SwiftData

/// `Visit` に紐づく写真 1 枚を表す SwiftData モデル。
///
/// CloudKit 互換要件:
/// - 全プロパティに default 値あり
/// - `visit` リレーションは optional 必須
/// - `imageData` は `@Attribute(.externalStorage)` で CloudKit Asset 化
///   (1 レコードあたり通常フィールド合計 1MB 上限、Asset は 50MB 上限)
///
/// 写真本体は保存時に `VisitPhotoStore` で最大 2048px / 5MB に強制縮小される。
/// `legacyFilename` は旧 `Documents/Photos/` ファイル名 (UUID.jpg) を保持し、
/// `PhotoMigration` で写真単位の冪等な重複検出キーとして使う。
@Model
final class VisitPhoto {
    var id: UUID = UUID()

    /// フルサイズ画像 (圧縮 JPEG、最大 2048px / 5MB に縮小済み)
    @Attribute(.externalStorage)
    var imageData: Data?

    /// 一覧表示用サムネイル (300px 圧縮 JPEG、~50KB、通常フィールド)
    var thumbnailData: Data?

    /// 表示順 (常に sort 経由で参照、配列順に依存しない)
    var orderIndex: Int = 0

    /// 作成日時
    var createdAt: Date = Date()

    /// 旧 `Documents/Photos/` ファイル名 (UUID.jpg)。
    /// マイグレーション元の特定に使う。新規追加分は nil。
    var legacyFilename: String?

    /// 親 `Visit` への逆参照 (CloudKit 互換のため optional 必須)
    var visit: Visit?

    init(imageData: Data?, thumbnailData: Data?, orderIndex: Int, legacyFilename: String? = nil) {
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.orderIndex = orderIndex
        self.legacyFilename = legacyFilename
    }
}
