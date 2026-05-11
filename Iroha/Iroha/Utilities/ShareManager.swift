//
//  ShareManager.swift
//  Iroha
//

import SwiftUI
import WebKit

@MainActor
enum ShareManager {

    private static var snapshotWebView: WKWebView?

    /// 地図共有エントリポイント。
    /// - Parameter stats: 表示する訪問集計。年別シェアは年でフィルタした visits で
    ///   作った `VisitStats` を渡すこと (全期間の stats を渡すと年別マップが
    ///   全期間表示になる)。
    static func shareMap(stats: VisitStats, year: Int? = nil) {
        let effectiveVisited = Set(stats.visitedPrefectures.map(\.name))

        renderMapSnapshot(stats: stats, visitedNames: effectiveVisited) { mapImage in
            guard let mapImage else { return }

            let visitedCount = effectiveVisited.count
            let conqueredRegions = Region.allCases.filter { region in
                let regionPrefs = Prefecture.all.filter { $0.region == region }
                return !regionPrefs.isEmpty && regionPrefs.allSatisfy { effectiveVisited.contains($0.name) }
            }.count

            let shareView = ShareCardView(
                mapImage: mapImage,
                visitedCount: visitedCount,
                conqueredRegions: conqueredRegions,
                visitedNames: effectiveVisited,
                year: year
            )

            let renderer = ImageRenderer(content: shareView)
            renderer.scale = 3

            guard let uiImage = renderer.uiImage else { return }

            let yearLabel = year.map { "\($0)年" } ?? ""
            let message = "\(yearLabel) \(visitedCount)/47 都道府県制覇！ #いろは #旅行記録"
            presentShareSheet(items: [uiImage, message])
        }
    }

    // MARK: - Map snapshot via WKWebView

    private static func renderMapSnapshot(
        stats: VisitStats,
        visitedNames: Set<String>,
        completion: @escaping @MainActor (UIImage?) -> Void
    ) {
        guard let url = Bundle.main.url(forResource: "map-full", withExtension: "svg"),
              let svgContent = try? String(contentsOf: url, encoding: .utf8) else {
            completion(nil)
            return
        }

        let html = buildSnapshotHTML(svgContent: svgContent, stats: stats, visitedNames: visitedNames)

        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 600), configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        snapshotWebView = webView

        let delegate = SnapshotDelegate { image in
            snapshotWebView = nil
            completion(image)
        }
        webView.navigationDelegate = delegate
        objc_setAssociatedObject(webView, "snapshotDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)

        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    private static func buildSnapshotHTML(svgContent: String, stats: VisitStats, visitedNames: Set<String>) -> String {
        let colorEntries = Prefecture.all.map { pref in
            let hex = visitedNames.contains(pref.name) ? stats.colorHex(for: pref) : "#DDDAD4"
            return "'\(pref.id)': '\(hex)'"
        }.joined(separator: ", ")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        * { margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; background: transparent; overflow: hidden; }
        svg { width: 100%; height: 100%; display: block; }
        .prefecture { fill: #DDDAD4; stroke: white; stroke-width: 0.6; }
        </style>
        </head>
        <body>
        \(svgContent)
        <script>
        (function() {
            var colors = {\(colorEntries)};
            var els = document.querySelectorAll('.prefecture');
            els.forEach(function(el) {
                el.removeAttribute('stroke');
                el.removeAttribute('stroke-width');
                el.removeAttribute('fill');
                var code = el.getAttribute('data-code');
                if (code && colors[code]) el.style.fill = colors[code];
            });
        })();
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Share sheet

    private static func presentShareSheet(items: [Any]) {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.keyWindow,
            let rootVC = window.rootViewController
        else { return }

        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        rootVC.present(controller, animated: true)
    }
}

// MARK: - Snapshot delegate

private final class SnapshotDelegate: NSObject, WKNavigationDelegate {
    let completion: @MainActor (UIImage?) -> Void

    init(completion: @escaping @MainActor (UIImage?) -> Void) {
        self.completion = completion
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let config = WKSnapshotConfiguration()
            config.snapshotWidth = NSNumber(value: 600)
            webView.takeSnapshot(with: config) { image, _ in
                DispatchQueue.main.async {
                    self?.completion(image)
                }
            }
        }
    }
}

// MARK: - Share card view

private struct ShareCardView: View {
    let mapImage: UIImage
    let visitedCount: Int
    let conqueredRegions: Int
    let visitedNames: Set<String>
    let year: Int?

    private let bgColor = Color(red: 0xF7/255, green: 0xF4/255, blue: 0xEF/255)
    private let textColor = Color(red: 0x1C/255, green: 0x1A/255, blue: 0x2A/255)
    private let subColor = Color(red: 0x92/255, green: 0x90/255, blue: 0xA8/255)
    private let accentColor = Color(red: 0x7F/255, green: 0x77/255, blue: 0xDD/255)
    private let accentDk = Color(red: 0x53/255, green: 0x4A/255, blue: 0xB7/255)

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 28)

            Text(verbatim: year.map { "\($0)年の旅" } ?? "すべての旅")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(textColor)
                .tracking(2)
                .padding(.bottom, 10)

            Image(uiImage: mapImage)
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 280)

            Spacer().frame(height: 20)

            Rectangle()
                .fill(subColor.opacity(0.2))
                .frame(width: 260, height: 0.5)

            Spacer().frame(height: 18)

            HStack(spacing: 32) {
                statColumn(
                    value: "\(visitedCount)",
                    total: "/ 47",
                    label: "都道府県"
                )
                statColumn(
                    value: "\(conqueredRegions)",
                    total: "/ 8",
                    label: "地方制覇"
                )
            }

            Spacer().frame(height: 14)

            regionChips

            Spacer().frame(height: 18)

            Rectangle()
                .fill(subColor.opacity(0.2))
                .frame(width: 260, height: 0.5)

            Spacer().frame(height: 14)

            Text("い ろ は")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(textColor)
                .tracking(6)

            Text("#いろは #旅行記録")
                .font(.system(size: 10))
                .foregroundColor(subColor)
                .padding(.top, 4)

            Spacer().frame(height: 24)
        }
        .frame(width: 340)
        .background(bgColor)
    }

    private func statColumn(value: String, total: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundColor(accentDk)
                Text(total)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(subColor)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(subColor)
                .tracking(1)
        }
    }

    private var regionChips: some View {
        let columns = 4
        let regions = Region.allCases
        let rows = stride(from: 0, to: regions.count, by: columns).map {
            Array(regions[$0..<min($0 + columns, regions.count)])
        }

        return VStack(spacing: 4) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 4) {
                    ForEach(row, id: \.rawValue) { region in
                        let isConquered = Prefecture.all
                            .filter { $0.region == region }
                            .allSatisfy { visitedNames.contains($0.name) }

                        HStack(spacing: 3) {
                            if isConquered {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(accentDk)
                            }
                            Text(region.localizedName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isConquered ? accentDk : subColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isConquered ? accentColor.opacity(0.12) : subColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}
