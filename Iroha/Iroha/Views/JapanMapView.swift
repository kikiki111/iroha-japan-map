//
//  JapanMapView.swift
//  Iroha
//

import SwiftUI
import SwiftData

// MARK: - JapanMapView

struct JapanMapView: View {
    var viewModel: MapViewModel

    @Environment(\.modelContext) private var modelContext
    @State var mapScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            mapCanvas
                .scaleEffect(mapScale)
                .onTapGesture { point in
                    viewModel.toggle(at: point, in: geometry.frame(in: .local), context: modelContext)
                    animateMilestoneIfNeeded()
                }
        }
        .accessibilityLabel("日本地図")
        .accessibilityHint("都道府県をタップして訪問記録を追加します")
    }

    // MARK: - Canvas

    private var mapCanvas: some View {
        Canvas { ctx, size in
            for shape in viewModel.prefectureShapes {
                guard let prefecture = viewModel.prefectures.first(where: { $0.id == shape.prefectureID })
                else { continue }
                drawShape(shape, color: viewModel.color(for: prefecture), ctx: &ctx, size: size)
            }
        }
    }

    // MARK: - Drawing helper

    private func drawShape(
        _ shape: PrefectureShape,
        color: Color,
        ctx: inout GraphicsContext,
        size: CGSize
    ) {
        for normalizedPath in shape.paths {
            var transform = CGAffineTransform(scaleX: size.width, y: size.height)
            guard let scaledPath = normalizedPath.copy(using: &transform) else { continue }
            let path = Path(scaledPath)
            ctx.fill(path, with: .color(color))
            ctx.stroke(
                path,
                with: .color(.white.opacity(0.8)),
                lineWidth: 0.8
            )
        }
    }

    // MARK: - Milestone animation

    private func animateMilestoneIfNeeded() {
        guard viewModel.isAllVisited else { return }
        withAnimation(.easeOut(duration: 0.12)) { mapScale = 1.06 }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.12)) { mapScale = 1.0 }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Prefecture.self, Visit.self, configurations: config)

    let viewModel = MapViewModel()
    viewModel.prefectures = (1...47).map { i in
        Prefecture(id: i, name: "Prefecture \(i)", region: Region.allCases[i % Region.allCases.count], latitude: 35.0)
    }

    return JapanMapView(viewModel: viewModel)
        .modelContainer(container)
        .frame(width: 390, height: 600)
}
