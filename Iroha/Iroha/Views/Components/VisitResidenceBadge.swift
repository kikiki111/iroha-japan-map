//
//  VisitResidenceBadge.swift
//  Iroha
//
//  居住記録のバッジ表示

import SwiftUI

/// 居住記録であることを示すバッジ。
///
/// 他のバッジ (`VisitTagBadge` 等) と違い期間情報を持つため、
/// `compact` で「居住」のみの短縮表示と期間付き表示を切り替える。
struct VisitResidenceBadge: View {
    let startDate: Date
    let endDate: Date?
    let isOngoing: Bool
    /// true なら期間を出さず「居住」ラベルのみ (バッジ列に並べる用)
    var compact: Bool = false

    var body: some View {
        // 書式は VisitCompanionBadge / VisitTransportBadge と同一。色だけ金茶。
        HStack(spacing: 3) {
            Image(systemName: "house.fill")
                .font(.system(size: 9))
            Text(compact ? "居住" : periodText)
                .font(.system(size: 10))
                .lineLimit(1)
        }
        .foregroundColor(.irohaSumikaDk)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.irohaSumikaLt.opacity(0.6))
        .clipShape(Capsule())
    }

    private var periodText: String {
        let start = Self.monthFormat(startDate)
        if isOngoing || endDate == nil {
            return "\(start) 〜 現在"
        }
        guard let endDate else { return "\(start) 〜 現在" }
        return "\(start) 〜 \(Self.monthFormat(endDate))"
    }

    private static func monthFormat(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().locale(Locale(identifier: "ja_JP")))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        VisitResidenceBadge(startDate: Date(), endDate: nil, isOngoing: true)
        VisitResidenceBadge(startDate: Date(), endDate: Date(), isOngoing: false)
        VisitResidenceBadge(startDate: Date(), endDate: nil, isOngoing: true, compact: true)
    }
    .padding()
}
