//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI

@Observable
final class MapViewModel {
    var prefectures: [Prefecture] = []

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
}
