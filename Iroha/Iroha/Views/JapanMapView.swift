//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 日本地図ビュー
/// MapViewModel.focusedPrefectureName の変化を受けてハイライト表示する
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]

    /// 訪問済みの都道府県名セット
    private var visitedNames: Set<String> {
        Set(visits.map { $0.prefectureName })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 都道府県グリッド（簡易マップ代替）
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(Prefecture.all) { prefecture in
                            PrefectureCell(
                                prefecture: prefecture,
                                isVisited: visitedNames.contains(prefecture.name),
                                isFocused: mapViewModel.focusedPrefectureName == prefecture.name
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("日本地図")
            .toolbar {
                if mapViewModel.focusedPrefectureName != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("クリア") {
                            mapViewModel.clearFocus()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - PrefectureCell

private struct PrefectureCell: View {
    let prefecture: Prefecture
    let isVisited: Bool
    let isFocused: Bool

    var body: some View {
        Text(prefecture.name)
            .font(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, minHeight: 40)
            .padding(4)
            .background(background)
            .foregroundStyle(isFocused ? Color.white : (isVisited ? Color.primary : Color.secondary))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocused ? Color.orange : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.spring(duration: 0.25), value: isFocused)
    }

    private var background: Color {
        if isFocused { return .orange }
        if isVisited { return .blue.opacity(0.25) }
        return Color(.systemGray5)
    }
}
