//
//  VisitTag.swift
//  Iroha
//

import Foundation

/// 旧 `Visit.tag` の型（旅行スタイル）。**移行元専用・新規利用禁止**。
///
/// 82e8657 で旅行スタイルをカスタム対応させた際、`Visit.tag` を `VisitTag?` から
/// `String?` に変更した。ローカル SQLite は双方とも `ZTAG VARCHAR` に rawValue を
/// 平文で格納するためマイグレーション不要だったが、**CloudKit では型が食い違った**。
/// SwiftData は enum を Data にアーカイブして送るため CloudKit 上の `CD_tag` は
/// BYTES で確定しており、String に変えた結果 import が毎回失敗した
/// (NSCocoaError 134420: desired NSString / given NSConcreteData)。import が
/// 失敗すると export も動かず、同期パイプライン全体が停止する。
///
/// CloudKit のフィールド型は後から変更できないため、`tag` を本 enum に戻して
/// `CD_tag` (BYTES) と型を一致させ、正となるスタイル ID は新設した
/// `Visit.styleID` (`CD_styleID` = STRING) に持たせる構成にした。
///
/// - Important: 表示用のプロパティ (displayName / iconName / 配色) は本 enum には
///   持たせない。UI は `TravelStyleCatalog` / `TravelStylePreset` に一本化済みで、
///   rawValue はそのまま `TravelStylePreset` の rawValue と対応する。
///   本 enum は `VisitStyleIDMigration` の移行元としてのみ読むこと。
enum VisitTag: String, Codable, CaseIterable {
    case none     = "none"
    case solo     = "solo"
    case family   = "family"
    case couple   = "couple"
    case friends  = "friends"

    // Legacy (選択肢には出ないが、既存レコードに実在するため残す)
    case dayTrip  = "dayTrip"
    case stay     = "stay"
    case lived    = "lived"
}
