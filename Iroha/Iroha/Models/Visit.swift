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
    /// 記録種別 (旅行 / 居住)。nil = 旧データ、`effectiveKind` で `.travel` に倒す。
    var kind: VisitKind?
    /// 旧 `date` 属性からのライトウェイトマイグレーション対応。
    /// 居住 (`kind == .residence`) の場合は居住開始日を表す。
    @Attribute(originalName: "date")
    var startDate: Date = Date()
    /// nil = 日帰り（startDate と同日）。**旅行専用**。
    /// 居住の終了日は `residenceEndDate` を使う (nil の意味が衝突するため分離)。
    var endDate: Date?
    /// 居住の終了日。`isResidenceOngoing == true` のときは nil。
    var residenceEndDate: Date?
    /// 現在も居住中か。true なら `residenceEndDate` は nil。
    var isResidenceOngoing: Bool = false
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
         note: String = "", tag: VisitTag = .none,
         kind: VisitKind = .travel,
         residenceEndDate: Date? = nil,
         isResidenceOngoing: Bool = false) {
        self.prefectureName     = prefectureName
        self.prefectureID       = prefectureID
        self.startDate          = startDate
        self.endDate            = endDate
        self.note               = note
        self.tag                = tag
        self.kind               = kind
        self.residenceEndDate   = residenceEndDate
        self.isResidenceOngoing = isResidenceOngoing
        self.photoFilename      = nil
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

    /// 記録種別の安全なアクセス（nil → .travel）。
    /// 旧データは `kind` を持たないため、すべて旅行として扱う。
    var effectiveKind: VisitKind {
        guard !isDeleted else { return .travel }
        return kind ?? .travel
    }

    /// 居住記録かどうか。集計・旅検出の除外判定に使う。
    var isResidence: Bool {
        effectiveKind == .residence
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

    // MARK: - Residence helpers

    /// 居住期間の表示テキスト。例: "2015年4月 〜 2019年3月" / "2019年4月 〜 現在"
    var residencePeriodText: String {
        guard !isDeleted else { return "" }
        let start = Self.residenceMonthFormat(startDate)
        if isResidenceOngoing || residenceEndDate == nil {
            return "\(start) 〜 現在"
        }
        guard let end = residenceEndDate else { return "\(start) 〜 現在" }
        return "\(start) 〜 \(Self.residenceMonthFormat(end))"
    }

    /// 居住期間の長さ表示。例: "4年" / "8か月"。1か月未満は nil。
    var residenceDurationText: String? {
        guard !isDeleted, isResidence else { return nil }
        let end = isResidenceOngoing ? Date() : (residenceEndDate ?? Date())
        guard end > startDate else { return nil }
        let parts = Calendar.current.dateComponents([.year, .month], from: startDate, to: end)
        let years = parts.year ?? 0
        let months = parts.month ?? 0
        if years > 0 {
            return months > 0 ? "\(years)年\(months)か月" : "\(years)年"
        }
        return months > 0 ? "\(months)か月" : nil
    }

    private static func residenceMonthFormat(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().locale(Locale(identifier: "ja_JP")))
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
