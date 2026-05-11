//
//  Visit.swift
//  Iroha
//

import Foundation
import SwiftData

/// 都道府県への訪問を表す SwiftData モデル
@Model
final class Visit {
    var prefectureName: String = ""
    /// `Prefecture.id` (1〜47)。`Prefecture` を SwiftData から外したため、
    /// 訪問先の参照キーとして保持する。既存 Visit は `VisitPrefectureMigration` で
    /// `prefectureName` から backfill される。
    var prefectureID: Int = 0
    /// 旧 `date` 属性からのライトウェイトマイグレーション対応
    @Attribute(originalName: "date")
    var startDate: Date = Date()
    /// nil = 日帰り（startDate と同日）
    var endDate: Date?
    var note: String = ""
    /// 訪問タグ（日帰り / 宿泊 / 居住）
    var tag: VisitTag?
    /// 写真ファイル名（Documents/Photos/ に保存）
    var photoFilename: String?
    /// サムネイル画像データ（リスト表示用、300px JPEG）
    var photoThumbnail: Data?
    /// 複数写真ファイル名
    var photoFilenames: [String] = []
    /// 複数写真サムネイル（CloudKit 互換のため単一 Data に JSON エンコード）
    var photoThumbnailsData: Data?
    /// 感情スタンプ（ムード記録）
    var mood: VisitMood?
    /// 移動手段（複数選択可、rawValue 配列）
    var transports: [String] = []
    /// 旅行名（任意）
    var tripName: String = ""
    /// 同行者（名前の配列）
    var companions: [String] = []
    /// 訪問場所（フリーテキスト）
    var location: String = ""
    /// 場所の緯度（MapKit 選択時のみ）
    var locationLatitude: Double?
    /// 場所の経度（MapKit 選択時のみ）
    var locationLongitude: Double?

    /// 写真リレーション (CloudKit 互換のため optional + default)。
    /// 新規追加分は `VisitPhotoStore` 経由でこちらに格納される。
    /// レガシープロパティ (`photoFilename` / `photoFilenames` / `photoThumbnail` /
    /// `photoThumbnailsData`) は移行完了確認まで保持し、`PhotoMigration` で
    /// `VisitPhoto` に転記する。表示は `sortedPhotoThumbnails` 等の互換ヘルパー経由。
    @Relationship(deleteRule: .cascade, inverse: \VisitPhoto.visit)
    var photos: [VisitPhoto]? = []

    init(prefectureName: String, prefectureID: Int = 0,
         startDate: Date, endDate: Date? = nil,
         note: String = "", tag: VisitTag = .none) {
        self.prefectureName = prefectureName
        self.prefectureID   = prefectureID
        self.startDate      = startDate
        self.endDate        = endDate
        self.note           = note
        self.tag            = tag
        self.photoFilename  = nil
    }

    var photoThumbnails: [Data] {
        get {
            guard let blob = photoThumbnailsData else { return [] }
            return (try? JSONDecoder().decode([Data].self, from: blob)) ?? []
        }
        set {
            photoThumbnailsData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue)
        }
    }

    /// タグの安全なアクセス（nil → .none）
    var effectiveTag: VisitTag {
        guard !isDeleted else { return .none }
        return tag ?? .none
    }

    var effectiveMood: VisitMood {
        guard !isDeleted else { return .none }
        return mood ?? .none
    }

    var effectiveTransports: [VisitTransport] {
        guard !isDeleted else { return [] }
        return transports.compactMap { VisitTransport(rawValue: $0) }.filter { $0 != .none }
    }

    /// 帰着日（nil の場合は startDate を返す）
    var effectiveEndDate: Date {
        guard !isDeleted else { return startDate }
        return endDate ?? startDate
    }

    /// レガシー単一写真 + 新複数写真を統合
    var allPhotoFilenames: [String] {
        guard !isDeleted else { return [] }
        if !photoFilenames.isEmpty { return photoFilenames }
        if let f = photoFilename { return [f] }
        return []
    }

    var allPhotoThumbnails: [Data] {
        guard !isDeleted else { return [] }
        if !photoThumbnails.isEmpty { return photoThumbnails }
        if let t = photoThumbnail { return [t] }
        return []
    }

    // MARK: - Photo compatibility helpers (Phase A 移行期間用)
    //
    // 新 `photos` リレーションと旧 legacy プロパティが共存する期間に、
    // 表示・カウントを破綻させないための統合ヘルパー。
    // `legacyFilename` で重複検出することで、移行済みの写真は新側のみカウント。

    /// 新 `photos` を `orderIndex` 順にソートして返す
    var sortedPhotos: [VisitPhoto] {
        guard !isDeleted else { return [] }
        return (photos ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    /// 写真の合計数 (新旧重複なし)
    var totalPhotoCount: Int {
        guard !isDeleted else { return 0 }
        let newPhotos = sortedPhotos
        let migratedNames = Set(newPhotos.compactMap(\.legacyFilename))
        let unmigratedLegacyCount = allPhotoFilenames.filter { !migratedNames.contains($0) }.count
        return newPhotos.count + unmigratedLegacyCount
    }

    /// 表示用サムネイル一覧 (新 `photos` 優先、未移行 legacy をフォールバック)
    var sortedPhotoThumbnails: [Data] {
        guard !isDeleted else { return [] }
        let newPhotos = sortedPhotos
        let migratedNames = Set(newPhotos.compactMap(\.legacyFilename))
        let newThumbs = newPhotos.compactMap(\.thumbnailData)

        // 未移行 legacy 分のサムネイルを追加 (順序維持)
        let legacyThumbs = zip(allPhotoFilenames, allPhotoThumbnails)
            .filter { !migratedNames.contains($0.0) }
            .map(\.1)

        return newThumbs + legacyThumbs
    }

    /// フルスクリーン表示用ファイル名一覧 (旧 PhotoStorageManager.loadImage と組み合わせる用途、
    /// 新 photos の場合は VisitPhoto.id の文字列を識別子として返す)
    var sortedPhotoFilenames: [String] {
        guard !isDeleted else { return [] }
        let newPhotos = sortedPhotos
        let migratedNames = Set(newPhotos.compactMap(\.legacyFilename))
        let newIDs = newPhotos.map { $0.id.uuidString }

        let legacyNames = allPhotoFilenames.filter { !migratedNames.contains($0) }
        return newIDs + legacyNames
    }

    var hasPhotos: Bool { totalPhotoCount > 0 }
    var hasCompanions: Bool { !companions.isEmpty }
    var hasLocation: Bool {
        guard !isDeleted else { return false }
        return !location.isEmpty
    }
}
