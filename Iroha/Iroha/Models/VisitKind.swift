//
//  VisitKind.swift
//  Iroha
//
//  記録種別（旅行 / 居住）

import SwiftUI

/// 記録の種別。
///
/// 旅行スタイル (`TravelStyle`: 一人旅 / 家族旅行 …) とは直交する軸として扱う。
/// 「家族と一緒に住んでいた」のように、居住でも旅行スタイルを選べる。
///
/// - Note: 他の enum と違い `.none` を持たない。「未設定」は `Visit.kind == nil`
///   (旧データ) で表し、`Visit.effectiveKind` が `.travel` にフォールバックする。
enum VisitKind: String, Codable, CaseIterable {
    case travel    = "travel"
    case residence = "residence"

    var displayName: String {
        switch self {
        case .travel:    return "旅行"
        case .residence: return "居住"
        }
    }

    var iconName: String {
        switch self {
        case .travel:    return "airplane"
        case .residence: return "house.fill"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .travel:    return .irohaFujiDk
        case .residence: return .irohaSumikaDk
        }
    }

    var backgroundColor: Color {
        switch self {
        case .travel:    return Color.irohaFujiLt.opacity(0.25)
        case .residence: return Color.irohaSumikaLt.opacity(0.3)
        }
    }
}
