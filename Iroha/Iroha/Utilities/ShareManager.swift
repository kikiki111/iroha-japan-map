//
//  ShareManager.swift
//  Iroha
//

import SwiftUI
import UIKit

/// 日本地図スナップショットをシステムのシェアシートで共有するユーティリティ
@MainActor
enum ShareManager {

    /// 訪問マップを画像化してシェアシートを開く
    static func shareMap(prefectures: [Prefecture]) {
        let visitedCount = prefectures.filter(\.isVisited).count
        let message      = "\(visitedCount)/47 都道府県制覇！ #Iroha #いろは"

        let renderer   = ImageRenderer(content: MapSnapshotView(prefectures: prefectures))
        renderer.scale = UIScreen.main.scale

        guard let uiImage = renderer.uiImage else { return }

        let items: [Any] = [uiImage, message]
        let controller   = UIActivityViewController(activityItems: items, applicationActivities: nil)

        guard
            let scene  = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.keyWindow
        else { return }

        if let popover = controller.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(
                x: window.bounds.midX, y: window.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        window.rootViewController?.present(controller, animated: true)
    }
}

// MARK: - MapSnapshotView

/// ImageRenderer でレンダリングするマップサムネイル（LazyVGrid を避け HStack で確実に全描画）
private struct MapSnapshotView: View {
    let prefectures: [Prefecture]

    private let cellsPerRow: Int   = 7
    private let cellWidth:  CGFloat = 44
    private let cellHeight: CGFloat = 28
    private let spacing:    CGFloat = 4

    private var rows: [[Prefecture]] {
        stride(from: 0, to: prefectures.count, by: cellsPerRow).map {
            Array(prefectures[$0 ..< min($0 + cellsPerRow, prefectures.count)])
        }
    }

    var body: some View {
        let gridWidth = CGFloat(cellsPerRow) * cellWidth + CGFloat(cellsPerRow - 1) * spacing
        let visitedCount = prefectures.filter(\.isVisited).count

        VStack(spacing: 10) {
            Text("Iroha 訪問マップ")
                .font(.headline)

            VStack(spacing: spacing) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.id) { pref in
                            SnapshotCell(prefecture: pref)
                                .frame(width: cellWidth, height: cellHeight)
                        }
                        if row.count < cellsPerRow {
                            Spacer()
                        }
                    }
                }
            }
            .frame(width: gridWidth)

            Text("\(visitedCount)/47 都道府県制覇！ #Iroha #いろは")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .frame(width: gridWidth + 32)
    }
}

// MARK: - SnapshotCell

private struct SnapshotCell: View {
    let prefecture: Prefecture

    var body: some View {
        Text(prefecture.name)
            .font(.system(size: 8))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(prefecture.visitColor())
            .foregroundStyle(prefecture.isVisited ? Color.white : Color(hex: "#555555"))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
