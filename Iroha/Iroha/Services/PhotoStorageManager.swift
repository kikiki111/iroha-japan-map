//
//  PhotoStorageManager.swift
//  Iroha
//

import UIKit

/// 訪問記録の写真をファイルシステムに保存・読込・削除するユーティリティ
enum PhotoStorageManager {
    private static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 画像を保存し、ファイル名を返す
    static func save(image: UIImage) -> String? {
        let filename = UUID().uuidString + ".jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let url = photosDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    /// サムネイル用の小さい画像データを生成
    static func generateThumbnail(from image: UIImage, maxSize: CGFloat = 300) -> Data? {
        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let thumbnail = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }

    /// ファイル名からフル画像を読み込み
    static func loadImage(filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// ファイルを削除
    static func delete(filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
