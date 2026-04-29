//
//  JapanMapWebView.swift
//  Iroha
//

import SwiftUI
import WebKit

// MARK: - WKWebView subclass

/// SVGベースの日本地図を表示するWKWebView。
/// map-full.svg（Geolonia）をHTMLとして読み込み、JavaScriptで色更新とタップ検出を行う。
final class JapanMapWKWebView: WKWebView {

    /// 都道府県コード（1〜47）を受け取るタップコールバック
    var onTap: ((Int) -> Void)?

    private var isPageLoaded = false
    private var latestColorMap: [String: String] = [:]
    private var latestHighlightCode: Int? // nil = ハイライトなし
    private var isDarkMode = false

    init() {
        let config = WKWebViewConfiguration()
        super.init(frame: .zero, configuration: config)
        configuration.userContentController.add(WeakScriptHandler(self), name: "mapHandler")
        scrollView.isScrollEnabled = false
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1
        scrollView.bounces = false
        isOpaque = false
        backgroundColor = .clear
        navigationDelegate = self
        loadMapHTML()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) unsupported") }

    // MARK: - Public interface

    func updateColors(_ colorMap: [String: String]) {
        latestColorMap = colorMap
    }

    func animateFill(code: Int, color: String) {
        guard isPageLoaded else { return }
        let js = "animateFill(\(code), '\(color)');"
        evaluateJavaScript(js, completionHandler: nil)
    }

    func updateHighlight(_ code: Int?) {
        latestHighlightCode = code
    }

    func updateDarkMode(_ dark: Bool) {
        isDarkMode = dark
    }

    func applyPendingUpdates() {
        if isPageLoaded { applyUpdates() }
    }


    /// 地方制覇アニメーション：指定都道府県を一時的にフラッシュ
    func flashPrefectures(codes: [Int], color: String, durationMs: Int, originalColors: [String: String]) {
        guard isPageLoaded else { return }
        let codesJSON = codes.map { "\($0)" }.joined(separator: ",")
        guard let origData = try? JSONSerialization.data(withJSONObject: originalColors),
              let origString = String(data: origData, encoding: .utf8) else { return }
        let js = "flashPrefectures([\(codesJSON)], '\(color)', \(durationMs), \(origString));"
        evaluateJavaScript(js, completionHandler: nil)
    }

    /// 全国制覇アニメーション：北→南ウェーブ
    func waveAnimation(codes: [Int], color: String, totalDurationSec: Double) {
        guard isPageLoaded else { return }
        let codesJSON = codes.map { "\($0)" }.joined(separator: ",")
        let js = "waveAnimation([\(codesJSON)], '\(color)', \(totalDurationSec));"
        evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - Private

    private func loadMapHTML() {
        guard let url = Bundle.main.url(forResource: "map-full", withExtension: "svg"),
              let svgContent = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        loadHTMLString(buildHTML(svgContent), baseURL: Bundle.main.bundleURL)
    }

    private func applyUpdates() {
        guard let json = try? JSONSerialization.data(withJSONObject: latestColorMap),
              let jsonString = String(data: json, encoding: .utf8) else { return }
        let highlightArg = latestHighlightCode.map { "\($0)" } ?? "null"
        let strokeColor = isDarkMode ? "#2A2840" : "white"
        let js = "setStrokeColor('\(strokeColor)'); updateColors(\(jsonString)); highlightPrefecture(\(highlightArg));"
        evaluateJavaScript(js, completionHandler: nil)
    }

    fileprivate func handleScriptMessage(_ body: Any) {
        guard let data = body as? [String: Any],
              let action = data["action"] as? String,
              let code = data["prefectureCode"] as? Int else { return }
        if action == "prefectureTapped" {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?(code)
        }
    }

    // MARK: - HTML template

    private func buildHTML(_ svgContent: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; background: transparent; overflow: hidden; }
        svg { width: 100%; height: 100%; display: block; }
        .prefecture {
            fill: #DDDAD4;
            stroke: white;
            stroke-width: 0.6;
            cursor: pointer;
        }
        @keyframes nurikake-glow {
            0%   { filter: drop-shadow(0 0 8px rgba(127,119,221,0.8)); }
            40%  { filter: drop-shadow(0 0 12px rgba(127,119,221,0.5)); }
            100% { filter: drop-shadow(0 0 0px rgba(127,119,221,0)); }
        }
        </style>
        </head>
        <body>
        \(svgContent)
        <script>
        (function() {
            var usesTouch = false;
            var defaultStroke = 'white';
            function setup() {
                var els = document.querySelectorAll('.prefecture');
                if (els.length === 0) { setTimeout(setup, 100); return; }
                els.forEach(function(el) {
                    el.removeAttribute('stroke');
                    el.removeAttribute('stroke-width');
                    el.removeAttribute('fill');
                    el.addEventListener('touchstart', function(e) { e.preventDefault(); usesTouch = true; }, { passive: false });
                    el.addEventListener('touchend', function(e) {
                        e.preventDefault();
                        handleTap(el);
                    });
                    el.addEventListener('click', function(e) { if (!usesTouch) handleTap(el); });
                });
            }
            function handleTap(el) {
                var code = parseInt(el.getAttribute('data-code'));
                if (!code || isNaN(code)) return;
                sendMessage('prefectureTapped', code);
            }
            function sendMessage(action, code) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mapHandler) {
                    window.webkit.messageHandlers.mapHandler.postMessage({ action: action, prefectureCode: code });
                }
            }
            window.updateColors = function(colorMap) {
                for (var code in colorMap) {
                    var el = document.querySelector('[data-code="' + code + '"]');
                    if (el) el.style.fill = colorMap[code];
                }
            };
            window.setStrokeColor = function(color) {
                defaultStroke = color;
                document.querySelectorAll('.prefecture').forEach(function(el) {
                    if (el.style.strokeWidth !== '2.5') {
                        el.style.stroke = defaultStroke;
                    }
                });
            };
            window.highlightPrefecture = function(code) {
                document.querySelectorAll('.prefecture').forEach(function(el) {
                    el.style.stroke = defaultStroke;
                    el.style.strokeWidth = '0.6';
                });
                if (code !== null && code !== undefined) {
                    var el = document.querySelector('[data-code="' + code + '"]');
                    if (el) {
                        el.style.stroke = '#7F77DD';
                        el.style.strokeWidth = '2.5';
                        el.parentNode.appendChild(el);
                    }
                }
            };
            window.animateFill = function(code, targetColor) {
                var el = document.querySelector('[data-code="' + code + '"]');
                if (!el) return;
                el.style.transition = 'none';
                el.style.animation = 'nurikake-glow 0.8s ease-out';
                setTimeout(function() {
                    el.style.transition = 'fill 0.6s ease-out';
                    el.style.fill = targetColor;
                }, 20);
                setTimeout(function() {
                    el.style.transition = 'fill 0.4s ease-in-out';
                    el.style.animation = '';
                }, 800);
            };
            window.flashPrefectures = function(codes, color, durationMs, originalColors) {
                codes.forEach(function(code) {
                    var el = document.querySelector('[data-code="' + code + '"]');
                    if (el) el.style.fill = color;
                });
                setTimeout(function() {
                    codes.forEach(function(code) {
                        var el = document.querySelector('[data-code="' + code + '"]');
                        if (el && originalColors[code]) el.style.fill = originalColors[code];
                    });
                }, durationMs);
            };
            window.waveAnimation = function(codes, color, totalDurationSec) {
                var count = codes.length;
                codes.forEach(function(code, index) {
                    var delay = (index / count) * totalDurationSec * 1000;
                    setTimeout(function() {
                        var el = document.querySelector('[data-code="' + code + '"]');
                        if (el) el.style.fill = color;
                    }, delay);
                });
            };
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', setup);
            } else {
                setup();
            }
        })();
        </script>
        </body>
        </html>
        """
    }
}

// MARK: - WKNavigationDelegate

extension JapanMapWKWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isPageLoaded = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.applyUpdates()
        }
    }
}

// MARK: - WeakScriptHandler (retain cycle 回避)

/// WKUserContentController による強参照を防ぐ弱参照ラッパー
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var parent: JapanMapWKWebView?
    init(_ parent: JapanMapWKWebView) { self.parent = parent }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "mapHandler" else { return }
        DispatchQueue.main.async { [weak self] in
            self?.parent?.handleScriptMessage(message.body)
        }
    }
}

// MARK: - UIViewRepresentable wrapper

/// JapanMapWKWebView を SwiftUI から使うためのラッパー
struct JapanMapWebViewWrapper: UIViewRepresentable {
    let prefectures: [Prefecture]
    var mapViewModel: MapViewModel
    @Environment(\.colorScheme) private var colorScheme

    final class Coordinator {
        var lastExecutedMilestone: MilestoneType?
        var previousDisplayMode: MapDisplayMode?
        var previousColorMap: [String: String] = [:]
        var deferredFillAnimations: [(code: Int, color: String)] = []
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> JapanMapWKWebView {
        JapanMapWKWebView()
    }

    func updateUIView(_ webView: JapanMapWKWebView, context: Context) {
        // タップコールバック（最新の prefectures を常にキャプチャ）
        webView.onTap = { [prefectures, mapViewModel] code in
            guard let pref = prefectures.first(where: { $0.id == code }) else { return }
            mapViewModel.focus(prefecture: pref)
        }
        // 色更新（塗りかけアニメーション検出付き）
        let newColorMap = buildColorMap()
        let displayMode = mapViewModel.displayMode
        let displayModeChanged = context.coordinator.previousDisplayMode.map { $0 != displayMode } ?? false
        let unvisitedHex = "#DDDAD4"
        let sheetOpen = mapViewModel.focusedPrefecture != nil

        if displayModeChanged {
            context.coordinator.deferredFillAnimations = []
        } else {
            // 新規訪問を検出してアニメーションキューに追加
            for (code, newColor) in newColorMap {
                let oldColor = context.coordinator.previousColorMap[code]
                if let oldColor, oldColor == unvisitedHex, newColor != unvisitedHex {
                    if let codeInt = Int(code) {
                        let alreadyQueued = context.coordinator.deferredFillAnimations.contains { $0.code == codeInt }
                        if !alreadyQueued {
                            context.coordinator.deferredFillAnimations.append((codeInt, newColor))
                        }
                    }
                }
            }
        }

        // シートが閉じた時にアニメーションを発火
        var animatedCodes: Set<String> = []
        if !sheetOpen && !context.coordinator.deferredFillAnimations.isEmpty {
            for (code, color) in context.coordinator.deferredFillAnimations {
                webView.animateFill(code: code, color: color)
                animatedCodes.insert("\(code)")
            }
            context.coordinator.deferredFillAnimations = []
        }

        // アニメーション対象外の県は通常の色更新
        let normalColorMap = newColorMap.filter { !animatedCodes.contains($0.key) }
        if !normalColorMap.isEmpty {
            webView.updateColors(normalColorMap)
        }
        context.coordinator.previousDisplayMode = displayMode
        context.coordinator.previousColorMap = newColorMap
        webView.updateHighlight(mapViewModel.focusedPrefecture?.id)
        webView.updateDarkMode(colorScheme == .dark)

        webView.applyPendingUpdates()

        // マイルストーンアニメーション（重複実行防止）
        if let milestone = mapViewModel.pendingMilestone,
           context.coordinator.lastExecutedMilestone != milestone {
            context.coordinator.lastExecutedMilestone = milestone

            switch milestone {
            case .regionConquest(let region):
                let codes = prefectures.filter { $0.region == region }.map(\.id)
                var originalColors: [String: String] = [:]
                for code in codes {
                    let hex = prefectures.first(where: { $0.id == code })?.visitColorHex() ?? "#DDDAD4"
                    originalColors["\(code)"] = hex
                }
                webView.flashPrefectures(codes: codes, color: "#AFA9EC", durationMs: 300, originalColors: originalColors)

            case .nationalConquest:
                let sortedCodes = prefectures
                    .sorted { $0.latitude > $1.latitude }
                    .map(\.id)
                webView.waveAnimation(codes: sortedCodes, color: "#534AB7", totalDurationSec: 3.0)

            default:
                break // firstVisit は CSS transition、halfConquest は SwiftUI scaleEffect で処理
            }
        }
    }

    // MARK: - Color map

    private func buildColorMap() -> [String: String] {
        let allVisited = mapViewModel.isAllVisited(prefectures: prefectures)
        let mode = mapViewModel.displayMode
        return Dictionary(uniqueKeysWithValues: prefectures.map { pref in
            let hex: String
            if allVisited {
                hex = "#534AB7"
            } else {
                switch mode {
                case .all:
                    hex = pref.visitColorHex()
                case .unvisited:
                    hex = pref.isVisited ? "#DDDAD4" : "#9B9890"
                }
            }
            return ("\(pref.id)", hex)
        })
    }
}
