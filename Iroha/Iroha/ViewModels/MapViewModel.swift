//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI

/// 地図と他の画面を連携させるビューモデル
@Observable
final class MapViewModel {
    /// 現在フォーカスされている都道府県名
    private(set) var focusedPrefectureName: String?

    // MARK: - Focus

    /// 指定した都道府県に地図をフォーカスする
    func focus(prefecture: String) {
        focusedPrefectureName = prefecture
    }

    /// フォーカスをクリアする
    func clearFocus() {
        focusedPrefectureName = nil
    }

    // MARK: - Coloring

    /// 全47都道府県を訪問済みかどうかを判定する
    func isAllVisited(visits: [Visit]) -> Bool {
        Set(visits.map { $0.prefectureName }).count == 47
    }

    /// 訪問回数に応じた都道府県の表示色を返す
    func color(for prefecture: Prefecture, visits: [Visit]) -> Color {
        let count = visits.filter { $0.prefectureName == prefecture.name }.count
        if isAllVisited(visits: visits) { return Color(hex: "#534AB7") }
        return prefecture.visitColor(visitCount: count)
    }
}
