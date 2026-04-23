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
    /// 都道府県コード（1〜47）を受け取るロングプレスコールバック
    var onLongPress: ((Int) -> Void)?

    private var isPageLoaded = false
    private var latestColorMap: [String: String] = [:]
    private var latestHighlightCode: Int? // nil = ハイライトなし

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
        if isPageLoaded { applyUpdates() }
    }

    func updateHighlight(_ code: Int?) {
        latestHighlightCode = code
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
        let js = "updateColors(\(jsonString)); highlightPrefecture(\(highlightArg));"
        evaluateJavaScript(js, completionHandler: nil)
    }

    fileprivate func handleScriptMessage(_ body: Any) {
        guard let data = body as? [String: Any],
              let action = data["action"] as? String,
              let code = data["prefectureCode"] as? Int else { return }
        switch action {
        case "prefectureTapped":
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap?(code)
        case "prefectureLongPressed":
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onLongPress?(code)
        default:
            break
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
            transition: fill 0.4s ease-in-out;
        }
        </style>
        </head>
        <body>
        \(svgContent)
        <script>
        (function() {
            var lastTapTime = 0;
            var lastTapCode = 0;
            var tapTimer = null;
            function setup() {
                var els = document.querySelectorAll('.prefecture');
                if (els.length === 0) { setTimeout(setup, 100); return; }
                els.forEach(function(el) {
                    el.addEventListener('touchstart', function(e) { e.preventDefault(); }, { passive: false });
                    el.addEventListener('touchend', function(e) {
                        e.preventDefault();
                        handleTap(el);
                    });
                    el.addEventListener('click', function(e) { handleTap(el); });
                });
            }
            function handleTap(el) {
                var code = parseInt(el.getAttribute('data-code'));
                if (!code || isNaN(code)) return;
                var now = Date.now();
                if (lastTapCode === code && now - lastTapTime < 300) {
                    clearTimeout(tapTimer);
                    lastTapTime = 0;
                    lastTapCode = 0;
                    sendMessage('prefectureLongPressed', code);
                } else {
                    lastTapTime = now;
                    lastTapCode = code;
                    tapTimer = setTimeout(function() {
                        sendMessage('prefectureTapped', code);
                        lastTapTime = 0;
                        lastTapCode = 0;
                    }, 300);
                }
            }
            function sendMessage(action, code) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mapHandler) {
                    window.webkit.messageHandlers.mapHandler.postMessage({ action: action, prefectureCode: code });
                }
            }
            function tap(el) {
                var code = parseInt(el.getAttribute('data-code'));
                if (!code || isNaN(code)) return;
                sendMessage('prefectureTapped', code);
            }
            function longPress(el) {
                var code = parseInt(el.getAttribute('data-code'));
                if (!code || isNaN(code)) return;
                sendMessage('prefectureLongPressed', code);
            }
            window.updateColors = function(colorMap) {
                for (var code in colorMap) {
                    var el = document.querySelector('[data-code="' + code + '"]');
                    if (el) el.style.fill = colorMap[code];
                }
            };
            window.highlightPrefecture = function(code) {
                document.querySelectorAll('.prefecture').forEach(function(el) {
                    el.style.stroke = 'white';
                    el.style.strokeWidth = '0.6';
                });
                if (code !== null && code !== undefined) {
                    var el = document.querySelector('[data-code="' + code + '"]');
                    if (el) {
                        el.style.stroke = '#7F77DD';
                        el.style.strokeWidth = '2.5';
                    }
                }
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

    final class Coordinator {
        var lastExecutedMilestone: MilestoneType?
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
        // ダブルタップコールバック（ブックマーク切り替え）
        webView.onLongPress = { [prefectures, mapViewModel] code in
            guard let pref = prefectures.first(where: { $0.id == code }) else { return }
            pref.isBookmarked.toggle()
            mapViewModel.bookmarkToast = pref.isBookmarked
                ? "\(pref.name)を行きたいリストに追加"
                : "\(pref.name)を行きたいリストから削除"
        }
        // 色更新
        webView.updateColors(buildColorMap())
        webView.updateHighlight(mapViewModel.focusedPrefecture?.id)

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
        return Dictionary(uniqueKeysWithValues: prefectures.map { pref in
            let hex: String
            if allVisited {
                hex = "#534AB7"
            } else if mapViewModel.showBookmarks && pref.isBookmarked && !pref.isVisited {
                hex = "#FFD980"
            } else {
                hex = pref.visitColorHex()
            }
            return ("\(pref.id)", hex)
        })
    }
}
