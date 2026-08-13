//
//  Visit.swift
//  Iroha
//

import Foundation
import SwiftData

/// 都道府県への訪問を表す SwiftData モデル
@Model
final class Visit {
    /// 先頭県の名前（レガシー互換用ミラー）。正は `prefectureIDs`。
    var prefectureName: String = ""
    /// `Prefecture.id` (1〜47)。`Prefecture` を SwiftData から外したため、
    /// 訪問先の参照キーとして保持する。既存 Visit は `VisitPrefectureMigration` で
    /// `prefectureName` から backfill される。
    ///
    /// - Important: 複数県対応後は **先頭県のミラー**であり、正は `prefectureIDs`。
    ///   旧バージョンアプリ (CloudKit 相互運用) と `TripDetector.chronological` が
    ///   このミラーに依存しているため、空にしてはならない。更新は
    ///   `setPrefectureIDs(_:)` を経由すること。
    var prefectureID: Int = 0
    /// 訪問した都道府県 ID の配列（訪問順、重複なし）。1 レコードで複数県を記録できる。
    /// 写真の `photoFilename` → `photoFilenames` と同じ流儀で旧単数フィールドを残し、
    /// 参照は `effectivePrefectureIDs` に一本化する。CloudKit 互換のため default 値必須。
    /// 居住 (`kind == .residence`) では常に 1 要素。
    var prefectureIDs: [Int] = []
    /// 記録種別 (旅行 / 居住)。nil = 旧データ、`effectiveKind` で `.travel` に倒す。
    var kind: VisitKind?
    /// 旧 `date` 属性からのライトウェイトマイグレーション対応。
    /// 居住 (`kind == .residence`) の場合は居住開始日を表す。
    @Attribute(originalName: "date")
    var startDate: Date = Date()
    /// nil = 日帰り（startDate と同日）。**旅行専用**。
    /// 居住の終了日は `residenceEndDate` を使う (nil の意味が衝突するため分離)。
    var endDate: Date?
    /// 旅行日の入力粒度。nil = `.day`（既存レコード互換）、`effectiveDateAccuracy` で吸収。
    /// 昔の旅行など日付を覚えていない記録のため、`.month` / `.year` では `startDate` に
    /// 代表日（月末 / 12/31、未来日は今日でクランプ）を入れる。**旅行専用** —
    /// 居住は `residencePeriodText` で既に年月粒度の表示を持つため常に `.day` 扱い。
    var dateAccuracy: DateAccuracy?
    /// 居住の終了日。`isResidenceOngoing == true` のときは nil。
    var residenceEndDate: Date?
    /// 現在も居住中か。true なら `residenceEndDate` は nil。
    var isResidenceOngoing: Bool = false
    var note: String = ""
    /// 旅行スタイル ID（正）。
    /// - プリセット: `TravelStylePreset.rawValue` ("solo" / "business" …)
    /// - ユーザー定義: `"u:" + UUID.uuidString`
    /// - 未選択: nil。レガシー互換で文字列 `"none"` も未選択として扱う
    ///
    /// - Important: 参照は `effectiveStyleID`、書き込みは `setStyleID(_:)` を経由すること。
    ///   直接代入すると旧 `tag` が残り、フォールバックで古いスタイルが復活する。
    var styleID: String?

    /// 【移行元・書き込み禁止】旧スタイル ID。
    ///
    /// CloudKit 上の `CD_tag` は BYTES で確定しているため、型を合わせる目的で
    /// `VisitTag?` (enum) のまま保持する。詳細な経緯は `VisitTag` のコメントを参照。
    ///
    /// - Important: 新規保存では書き込まない。`VisitStyleIDMigration` が `styleID` へ
    ///   転記し、スタイル変更時は `setStyleID(_:)` が nil にクリアする。
    ///   写真の `photoFilenames` と同じく、移行完了確認後に別リリースで削除する。
    /// - Warning: `@Attribute(originalName:)` は付けないこと。CloudKit 連携ストアでは
    ///   属性のリネーム自体が禁止されており、名前を変えると `CD_tag` との対応も崩れる。
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
         prefectureIDs: [Int] = [],
         startDate: Date, endDate: Date? = nil,
         note: String = "", styleID: String? = nil,
         kind: VisitKind = .travel,
         residenceEndDate: Date? = nil,
         isResidenceOngoing: Bool = false,
         dateAccuracy: DateAccuracy = .day) {
        self.prefectureName     = prefectureName
        self.prefectureID       = prefectureID
        // 単一県で初期化された場合も配列側を埋め、migration 待ちの中間状態を作らない
        self.prefectureIDs      = prefectureIDs.isEmpty
            ? (prefectureID == 0 ? [] : [prefectureID])
            : prefectureIDs
        self.startDate          = startDate
        self.endDate            = endDate
        self.note               = note
        // 旧 tag には書き込まない (CD_tag は BYTES 固定の移行元。VisitTag を参照)
        self.styleID            = styleID
        self.kind               = kind
        self.residenceEndDate   = residenceEndDate
        self.isResidenceOngoing = isResidenceOngoing
        self.dateAccuracy       = dateAccuracy
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

    /// スタイル ID の安全なアクセス。未選択（nil / レガシー `"none"`）は nil に正規化する。
    ///
    /// 移行前のレコード（`styleID` が空で旧 `tag` に値が残っている）も拾う。
    /// `effectivePrefectureIDs` が `prefectureID` にフォールバックするのと同じ考え方で、
    /// `VisitStyleIDMigration` 実行前や旧バージョン端末から CloudKit 経由で降ってきた
    /// 直後にスタイル表示が消えるのを防ぐ。
    var effectiveStyleID: String? {
        guard !isDeleted else { return nil }
        guard let raw = styleID ?? tag?.rawValue,
              raw != TravelStyleID.noneSentinel else { return nil }
        return raw
    }

    /// 旅行スタイルを設定し、旧 `tag` をクリアする。
    ///
    /// 旧 `tag` を残したまま `styleID` だけを nil にすると、`effectiveStyleID` の
    /// フォールバックが旧値を拾って「スタイルを外したのに復活する」状態になる。
    /// さらに `VisitStyleIDMigration` の移行条件 (`styleID == nil && tag != nil`) にも
    /// 合致して次回起動で書き戻されるため、解除が永久にできなくなる。
    /// 書き込みは `setPrefectureIDs(_:)` と同様に必ずこのメソッドへ集約すること。
    func setStyleID(_ id: String?) {
        styleID = id
        tag = nil
    }

    var effectiveMood: VisitMood {
        guard !isDeleted else { return .none }
        return mood ?? .none
    }

    var effectiveTransports: [VisitTransport] {
        guard !isDeleted else { return [] }
        return transports.compactMap { VisitTransport(rawValue: $0) }.filter { $0 != .none }
    }

    // MARK: - Prefecture helpers (複数県対応)
    //
    // 新 `prefectureIDs` と旧 `prefectureID` / `prefectureName` が共存する。
    // 参照側は必ず `effectivePrefectureIDs` / `effectivePrefectureNames` を使い、
    // 書き込みは `setPrefectureIDs(_:)` に集約してミラーの不変条件を守る。
    //
    // 不変条件: prefectureIDs.first == prefectureID
    //           && prefectureName == Prefecture.by(id: prefectureID)?.name

    /// 複数県を並べるときの区切り (Trip の経路表示と揃える)
    static let prefectureSeparator = " → "

    /// 集計・地図塗り分けに使う都道府県 ID 群（訪問順、重複なし）。
    ///
    /// - Important: `prefectureIDs` が空のときの `prefectureID` フォールバックは、
    ///   CloudKit で旧バージョン端末から降ってきた直後 (migration 前) に記録が
    ///   集計から消えるのを防ぐためのもの。削除しないこと。
    var effectivePrefectureIDs: [Int] {
        guard !isDeleted else { return [] }
        if prefectureIDs.isEmpty {
            return prefectureID == 0 ? [] : [prefectureID]
        }
        // 大半のレコードは 1 県なので Set 生成を省く
        if prefectureIDs.count == 1 { return prefectureIDs }
        var seen = Set<Int>()
        return prefectureIDs.filter { seen.insert($0).inserted }
    }

    /// 表示用の都道府県名（訪問順）。ID が 1 つも解決できない旧データ (異表記など) は
    /// `prefectureName` をそのまま返し、画面から記録が消えないようにする。
    var effectivePrefectureNames: [String] {
        guard !isDeleted else { return [] }
        let names = effectivePrefectureIDs.compactMap { Prefecture.by(id: $0)?.name }
        if names.isEmpty {
            return prefectureName.isEmpty ? [] : [prefectureName]
        }
        return names
    }

    /// 「京都府 → 大阪府 → 兵庫県」形式の表示文字列。
    var prefectureDisplayName: String {
        effectivePrefectureNames.joined(separator: Self.prefectureSeparator)
    }

    /// 幅の限られた箇所向けの省略版。`limit` 県まで連結し、超過分は「ほか N 県」を付す。
    func prefectureDisplayName(limit: Int) -> String {
        let names = effectivePrefectureNames
        guard limit > 0, names.count > limit else {
            return names.joined(separator: Self.prefectureSeparator)
        }
        return names.prefix(limit).joined(separator: Self.prefectureSeparator)
            + " ほか\(names.count - limit)県"
    }

    /// 都道府県 ID 群を設定し、旧 `prefectureID` / `prefectureName` に先頭県をミラーする。
    ///
    /// 居住 (`isResidence`) は先頭 1 県に切り詰める。数年に及ぶ居住期間を複数県に
    /// またがらせると `VisitStats.residenceIDs` が水増しされ「住んだ県」の件数が狂うため、
    /// UI 側のガードに加えてモデル層でも防ぐ。
    /// - Note: 空配列は無視する (Visit は必ず 1 県以上を持つ。VisitFormView は
    ///   保存ボタンの `disabled` で空を弾いている)。
    func setPrefectureIDs(_ ids: [Int]) {
        var seen = Set<Int>()
        var unique = ids.filter { seen.insert($0).inserted }
        if isResidence, unique.count > 1 {
            unique = Array(unique.prefix(1))
        }
        guard let first = unique.first else { return }
        prefectureIDs  = unique
        prefectureID   = first
        prefectureName = Prefecture.by(id: first)?.name ?? prefectureName
    }

    /// 帰着日（nil の場合は startDate を返す）
    var effectiveEndDate: Date {
        guard !isDeleted else { return startDate }
        return endDate ?? startDate
    }

    // MARK: - Date accuracy helpers

    /// 日付精度の安全なアクセス（nil → .day）。
    /// 居住は年月粒度の専用表示 (`residencePeriodText`) を持つため、精度の概念を適用しない。
    var effectiveDateAccuracy: DateAccuracy {
        guard !isDeleted, !isResidence else { return .day }
        return dateAccuracy ?? .day
    }

    /// 日付が曖昧（日が確定していない）か。
    /// 旅の自動グルーピング・「◯年前の今日」・四季バッジの除外判定に使う。
    var isDateAmbiguous: Bool {
        guard !isDeleted else { return false }
        return effectiveDateAccuracy.isAmbiguous
    }

    /// 泊数。曖昧な日付・居住では算出しない（nil）。
    /// 「N泊M日」表示と `nightOwl` バッジはこの nil を見て除外する。
    var nightCount: Int? {
        guard !isDeleted, !isResidence, effectiveDateAccuracy == .day else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end   = calendar.startOfDay(for: effectiveEndDate)
        return calendar.dateComponents([.day], from: start, to: end).day
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
