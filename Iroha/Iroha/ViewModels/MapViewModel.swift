//
//  MapViewModel.swift
//  Iroha
//

import SwiftUI

/// 地図と他の画面を連携させるビューモデル
@Observable
@MainActor
final class MapViewModel {
    /// 現在フォーカスされている都道府県
    private(set) var focusedPrefecture: Prefecture?

    // MARK: - Focus

    func focus(prefecture: Prefecture) {
        focusedPrefecture = prefecture
    }

    func clearFocus() {
        focusedPrefecture = nil
    }

    // MARK: - Coloring

    /// 全47都道府県を訪問済みかどうかを判定する
    func isAllVisited(prefectures: [Prefecture]) -> Bool {
        prefectures.count == 47 && prefectures.allSatisfy { $0.isVisited }
    }

    /// 訪問回数に応じた都道府県の表示色を返す
    func color(for prefecture: Prefecture, allPrefectures: [Prefecture]) -> Color {
        if isAllVisited(prefectures: allPrefectures) { return Color(hex: "#534AB7") }
        return prefecture.visitColor()
    }
}
