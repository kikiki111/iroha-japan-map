//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// GeoJSON + Canvas の代わりに Geolonia SVG + WKWebView で日本地図を描画するビュー。
/// 訪問状態に応じた色更新とタップによる都道府県フォーカスをサポートする。
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    var body: some View {
        JapanMapWebViewWrapper(prefectures: prefectures, mapViewModel: mapViewModel)
            .aspectRatio(0.9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .scaleEffect(mapViewModel.mapScale)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    ScrollView {
        JapanMapView(mapViewModel: vm)
            .padding()
    }
    .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
