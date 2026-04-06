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

    /// 指定した都道府県に地図をフォーカスする
    func focus(prefecture: String) {
        focusedPrefectureName = prefecture
    }

    /// フォーカスをクリアする
    func clearFocus() {
        focusedPrefectureName = nil
    }
}
