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

    /// 訪問先都道府県への逆参照
    var prefecture: Prefecture?

    init(prefectureName: String, startDate: Date, endDate: Date? = nil,
         note: String = "", tag: VisitTag = .none) {
        self.prefectureName = prefectureName
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

    var hasPhotos: Bool { !allPhotoFilenames.isEmpty }
    var hasCompanions: Bool { !companions.isEmpty }
    var hasLocation: Bool {
        guard !isDeleted else { return false }
        return !location.isEmpty
    }
}
