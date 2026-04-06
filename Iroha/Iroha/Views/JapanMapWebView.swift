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
              action == "prefectureTapped",
              let code = data["prefectureCode"] as? Int else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onTap?(code)
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
        </style>
        </head>
        <body>
        \(svgContent)
        <script>
        (function() {
            function setup() {
                var els = document.querySelectorAll('.prefecture');
                if (els.length === 0) { setTimeout(setup, 100); return; }
                els.forEach(function(el) {
                    el.addEventListener('touchstart', function(e) { e.preventDefault(); }, { passive: false });
                    el.addEventListener('touchend', function(e) {
                        e.preventDefault();
                        tap(el);
                    });
                    el.addEventListener('click', function(e) { tap(el); });
                });
            }
            function tap(el) {
                var code = parseInt(el.getAttribute('data-code'));
                if (!code || isNaN(code)) return;
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mapHandler) {
                    window.webkit.messageHandlers.mapHandler.postMessage({ action: 'prefectureTapped', prefectureCode: code });
                }
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
                        el.style.stroke = '#FF6B00';
                        el.style.strokeWidth = '2.5';
                    }
                }
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

    func makeUIView(context: Context) -> JapanMapWKWebView {
        let webView = JapanMapWKWebView()
        return webView
    }

    func updateUIView(_ webView: JapanMapWKWebView, context: Context) {
        // タップコールバック（最新の prefectures を常にキャプチャ）
        webView.onTap = { [prefectures, mapViewModel] code in
            guard let pref = prefectures.first(where: { $0.id == code }) else { return }
            mapViewModel.focus(prefecture: pref)
        }
        webView.updateColors(buildColorMap())
        webView.updateHighlight(mapViewModel.focusedPrefecture?.id)
    }

    // MARK: - Color map

    private func buildColorMap() -> [String: String] {
        let allVisited = mapViewModel.isAllVisited(prefectures: prefectures)
        return Dictionary(uniqueKeysWithValues: prefectures.map { pref in
            let hex = allVisited ? "#534AB7" : pref.visitColorHex()
            return ("\(pref.id)", hex)
        })
    }
}
