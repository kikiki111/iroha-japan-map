//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI
import SwiftData

@Observable
final class MapViewModel {
    var prefectures: [Prefecture] = []

    /// GeoJSON から読み込んだ都道府県シェイプ（正規化座標）。
    var prefectureShapes: [PrefectureShape] = GeoJSONParser.load()

    /// 全47都道府県をすべて1回以上訪問済みかどうか。
    var isAllVisited: Bool {
        prefectures.count == 47 && prefectures.allSatisfy { $0.visitCount >= 1 }
    }

    /// isAllVisited を考慮した都道府県の表示色を返す。
    func color(for prefecture: Prefecture) -> Color {
        if isAllVisited {
            return Color(hex: "#534AB7")
        }
        return prefecture.visitColor()
    }

    /// `rect` 内の `point` でヒットテストを行い、マッチした都道府県の訪問状態をトグルする。
    func toggle(at point: CGPoint, in rect: CGRect, context: ModelContext) {
        let normalized = CGPoint(
            x: (point.x - rect.minX) / rect.width,
            y: (point.y - rect.minY) / rect.height
        )

        guard let shape = prefectureShapes.first(where: { shape in
            shape.paths.contains { $0.contains(normalized) }
        }) else { return }

        guard let prefecture = prefectures.first(where: { $0.id == shape.prefectureID }) else { return }

        if prefecture.isVisited {
            if let visit = prefecture.visits.last {
                context.delete(visit)
            }
        } else {
            let visit = Visit(date: Date())
            visit.prefecture = prefecture
            context.insert(visit)
        }
    }
}
