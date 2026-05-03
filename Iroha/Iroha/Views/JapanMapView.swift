//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// GeoJSON + Canvas の代わりに Geolonia SVG + WKWebView で日本地図を描画するビュー。
/// 訪問状態に応じた色更新とタップによる都道府県フォーカスをサポートする。
/// ピンチ / ダブルタップ / ドラッグでユーザーズーム + パンに対応する。
struct JapanMapView: View {
    var mapViewModel: MapViewModel

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    private let doubleTapScale: CGFloat = 2.5
    private let dragMinimumDistance: CGFloat = 10
    private let zoomAnimationDuration: Double = 0.25

    @State private var userScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let liveScale = clamped(userScale * pinchScale)
            let liveOffset = clampedOffset(
                CGSize(
                    width: offset.width + dragOffset.width,
                    height: offset.height + dragOffset.height
                ),
                scale: liveScale,
                size: proxy.size
            )

            JapanMapWebViewWrapper(prefectures: prefectures, mapViewModel: mapViewModel)
                .transaction { $0.animation = nil }
                .scaleEffect(mapViewModel.mapScale * liveScale)
                .offset(liveOffset)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .simultaneousGesture(magnificationGesture(size: proxy.size))
                .simultaneousGesture(dragGesture(size: proxy.size))
                .simultaneousGesture(doubleTapGesture())
        }
        .aspectRatio(0.9, contentMode: .fit)
    }

    // MARK: - Gestures

    private func magnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .updating($pinchScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let newScale = clamped(userScale * value)
                userScale = newScale
                offset = clampedOffset(offset, scale: newScale, size: size)
            }
    }

    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: dragMinimumDistance)
            .updating($dragOffset) { value, state, _ in
                guard userScale > minScale else { return }
                state = value.translation
            }
            .onEnded { value in
                guard userScale > minScale else { return }
                let combined = CGSize(
                    width: offset.width + value.translation.width,
                    height: offset.height + value.translation.height
                )
                offset = clampedOffset(combined, scale: userScale, size: size)
            }
    }

    private func doubleTapGesture() -> some Gesture {
        TapGesture(count: 2).onEnded {
            withAnimation(.easeInOut(duration: zoomAnimationDuration)) {
                if userScale > minScale {
                    userScale = minScale
                    offset = .zero
                } else {
                    userScale = doubleTapScale
                }
            }
        }
    }

    // MARK: - Helpers

    private func clamped(_ scale: CGFloat) -> CGFloat {
        min(max(scale, minScale), maxScale)
    }

    private func clampedOffset(_ raw: CGSize, scale: CGFloat, size: CGSize) -> CGSize {
        guard scale > minScale else { return .zero }
        let maxX = (scale - 1) * size.width / 2
        let maxY = (scale - 1) * size.height / 2
        return CGSize(
            width: min(max(raw.width, -maxX), maxX),
            height: min(max(raw.height, -maxY), maxY)
        )
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
