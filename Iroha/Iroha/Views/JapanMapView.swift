//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 日本地図グリッド（NavigationStack は親 View が管理する）
/// MapViewModel.focusedPrefecture の変化を受けてハイライト表示する
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
            ForEach(prefectures) { prefecture in
                PrefectureCell(
                    prefecture: prefecture,
                    isVisited: prefecture.isVisited,
                    isFocused: mapViewModel.focusedPrefecture?.name == prefecture.name
                )
            }
        }
        .padding()
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
        return prefecture.visitColor()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    ScrollView {
        JapanMapView(mapViewModel: vm)
    }
    .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
