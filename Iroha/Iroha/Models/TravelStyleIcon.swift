//
//  TravelStyleIcon.swift
//  Iroha
//
//  ユーザー定義スタイルで選べる SF Symbol

import Foundation

/// 旅行スタイルのアイコン候補。
///
/// - Note: `Image(systemName: "")` は SwiftUI で警告になるため、
///   アイコン未設定・レガシースタイルには `fallback` を使う。
enum TravelStyleIcon {
    static let fallback = "tag"

    /// パレット選択 UI に出す 24 種。プリセット専用のアイコンは重複感を避けて除外する。
    static let selectable: [String] = [
        // 人
        "person", "person.2", "person.3", "figure.and.child.holdinghands",
        // 気持ち・記号
        "heart", "star", "sparkles", "flame",
        // 自然
        "leaf", "mountain.2", "sun.max", "moon.stars",
        // 乗物
        "airplane", "car.fill", "tram.fill", "ferry.fill",
        // 場面・道具
        "briefcase", "backpack", "camera", "fork.knife",
        "cup.and.saucer.fill", "tent", "music.note", "gift"
    ]

    /// 空文字を `fallback` に読み替える
    static func resolved(_ name: String) -> String {
        name.isEmpty ? fallback : name
    }
}
