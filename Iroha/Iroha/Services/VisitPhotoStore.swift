//
//  VisitPhotoStore.swift
//  Iroha
//

import UIKit
import SwiftData

/// `VisitPhoto` の保存・取得・削除を扱うストア。
///
/// 重要: CloudKit Asset の上限 (50MB) と通常フィールド合計上限 (1MB) に
/// 収めるため、保存時に **必ず** 最大 2048px / 5MB 以内に強制縮小する。
enum VisitPhotoStore {

    /// 1 写真あたりの長辺最大ピクセル数。これを超える画像はリサイズされる。
    static let maxPixelDimension: CGFloat = 2048

    /// 1 写真あたりの最大バイト数 (CloudKit Asset 余裕確保)。
    static let maxByteSize: Int = 5 * 1024 * 1024 // 5MB

    /// 初期 JPEG 圧縮率。サイズ超過時は段階的に下げる。
    static let initialCompressionQuality: CGFloat = 0.8

    /// 圧縮率の下限 (これを下回るほどには下げない)。
    static let minCompressionQuality: CGFloat = 0.4

    /// サムネイルの長辺ピクセル数。
    static let thumbnailDimension: CGFloat = 300

    /// サムネイル JPEG 圧縮率。
    static let thumbnailCompressionQuality: CGFloat = 0.7

    // MARK: - Public API

    /// `UIImage` から `VisitPhoto` を生成して `Visit` に追加する。
    /// 画像は最大 2048px / 5MB 以内に強制縮小される。
    @discardableResult
    static func append(image: UIImage, to visit: Visit, in context: ModelContext, legacyFilename: String? = nil) -> VisitPhoto? {
        guard let imageData = compressedFullImageData(from: image),
              let thumbnailData = thumbnailData(from: image) else {
            return nil
        }

        let nextOrder = (visit.photos ?? []).map(\.orderIndex).max().map { $0 + 1 } ?? 0
        let photo = VisitPhoto(
            imageData: imageData,
            thumbnailData: thumbnailData,
            orderIndex: nextOrder,
            legacyFilename: legacyFilename
        )
        photo.visit = visit
        if visit.photos == nil { visit.photos = [] }
        visit.photos?.append(photo)
        context.insert(photo)
        return photo
    }

    /// 既存ファイルデータ (旧 Documents/Photos/ から読み込んだもの) を
    /// `VisitPhoto` として `Visit` に追加する。`PhotoMigration` 用。
    @discardableResult
    static func appendFromLegacyFileData(_ fileData: Data, legacyFilename: String, to visit: Visit, in context: ModelContext) -> VisitPhoto? {
        guard let image = UIImage(data: fileData) else { return nil }
        return append(image: image, to: visit, in: context, legacyFilename: legacyFilename)
    }

    // MARK: - Image processing

    /// フルサイズ画像を最大 2048px / 5MB 以内に縮小して JPEG エンコード。
    static func compressedFullImageData(from image: UIImage) -> Data? {
        let resized = resizedIfNeeded(image, maxDimension: maxPixelDimension)
        var quality = initialCompressionQuality

        guard var data = resized.jpegData(compressionQuality: quality) else { return nil }

        // サイズ超過なら圧縮率を段階的に下げる (0.8 → 0.7 → 0.6 → 0.5 → 0.4)
        while data.count > maxByteSize && quality > minCompressionQuality {
            quality -= 0.1
            guard let next = resized.jpegData(compressionQuality: quality) else { break }
            data = next
        }
        return data
    }

    /// サムネイル (300px、JPEG 圧縮率 0.7) を生成。
    static func thumbnailData(from image: UIImage) -> Data? {
        let thumb = resizedIfNeeded(image, maxDimension: thumbnailDimension)
        return thumb.jpegData(compressionQuality: thumbnailCompressionQuality)
    }

    /// 長辺が `maxDimension` 以下になるようリサイズ (元が小さい場合はそのまま)。
    static func resizedIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longSide = max(image.size.width, image.size.height)
        guard longSide > maxDimension else { return image }
        let scale = maxDimension / longSide
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Lookup / delete

    /// `Visit` の `photos` から指定 `VisitPhoto.id` を持つ写真を返す。
    static func photo(in visit: Visit, withID id: UUID) -> VisitPhoto? {
        visit.photos?.first { $0.id == id }
    }

    /// 指定写真を削除。`@Relationship(.cascade)` により Visit 側からも自動的に消える。
    static func delete(_ photo: VisitPhoto, in context: ModelContext) {
        context.delete(photo)
    }

    // MARK: - Hybrid load (Phase A 移行期間用)

    /// `Visit.sortedPhotoFilenames` の識別子からフルサイズ画像を取得する。
    /// - 識別子が UUID 形式 → 新 `VisitPhoto.imageData` から
    /// - それ以外 → 旧 `Documents/Photos/{filename}` から (`PhotoStorageManager`)
    static func loadFullImage(for identifier: String, in visit: Visit) -> UIImage? {
        if let uuid = UUID(uuidString: identifier),
           let photo = visit.sortedPhotos.first(where: { $0.id == uuid }),
           let data = photo.imageData {
            return UIImage(data: data)
        }
        return PhotoStorageManager.loadImage(filename: identifier)
    }
}
