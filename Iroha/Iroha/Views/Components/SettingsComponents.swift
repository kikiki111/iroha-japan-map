//
//  SettingsComponents.swift
//  Iroha
//
//  設定画面とそのサブ画面で共有する行・グループの部品

import SwiftUI

/// 設定 UI の共通寸法。
///
/// - Note: `SettingsGroup` / `SettingsRowLayout` がジェネリック型で、
///   ジェネリック型は static 格納プロパティを持てないためファイルスコープに置く。
enum SettingsMetrics {
    // 見出し
    static let headerFontSize: CGFloat = 13
    static let headerTracking: CGFloat = 2
    static let headerHPadding: CGFloat = 20
    static let headerTopPadding: CGFloat = 16
    static let headerBottomPadding: CGFloat = 5

    // カード枠
    static let groupCornerRadius: CGFloat = 12
    static let groupBorderWidth: CGFloat = 0.5
    static let groupHPadding: CGFloat = 14

    // アイコン
    static let iconFontSize: CGFloat = 15
    static let iconSize: CGFloat = 26

    // 行
    static let rowSpacing: CGFloat = 10
    static let rowTextSpacing: CGFloat = 2
    static let rowLabelSize: CGFloat = 15
    static let rowCaptionSize: CGFloat = 11
    static let rowHPadding: CGFloat = 14
    static let rowVPadding: CGFloat = 8

    // 区切り線の字下げ
    static let dividerLeadingWithIcon: CGFloat = 50
    static let dividerLeadingWithoutIcon: CGFloat = 14

    // 補足文
    static let footnoteFontSize: CGFloat = 11
    static let footnoteHPadding: CGFloat = 20
    static let footnoteTopPadding: CGFloat = 6
}

/// 設定セクションの見出し
struct SettingsSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: SettingsMetrics.headerFontSize, weight: .bold))
            .foregroundColor(.irohaSumi3)
            .tracking(SettingsMetrics.headerTracking)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SettingsMetrics.headerHPadding)
            .padding(.top, SettingsMetrics.headerTopPadding)
            .padding(.bottom, SettingsMetrics.headerBottomPadding)
    }
}

/// 設定行をまとめるカード枠
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.irohaCard)
        .clipShape(RoundedRectangle(cornerRadius: SettingsMetrics.groupCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsMetrics.groupCornerRadius)
                .stroke(Color.irohaWashi3, lineWidth: SettingsMetrics.groupBorderWidth)
        )
        .padding(.horizontal, SettingsMetrics.groupHPadding)
    }
}

/// 設定行の先頭に置くアイコン
///
/// - Note: `bg` は現状レンダリングに使っていない。既存 `SettingsView` の挙動を
///   そのまま引き継いだもので、色を反映させると全行の見た目が変わるため保留する。
struct SettingsIcon: View {
    let icon: String
    var bg: Color = .clear

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: SettingsMetrics.iconFontSize))
            .foregroundColor(.irohaSumi2)
            .frame(width: SettingsMetrics.iconSize, height: SettingsMetrics.iconSize)
    }
}

/// 設定行の共通レイアウト（アイコン + ラベル + 右端の任意ビュー）
struct SettingsRowLayout<Trailing: View>: View {
    let icon: String?
    var iconBg: Color = .clear
    let label: String
    var caption: String?
    var verticalPadding: CGFloat = SettingsMetrics.rowVPadding
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: SettingsMetrics.rowSpacing) {
            if let icon {
                SettingsIcon(icon: icon, bg: iconBg)
            }
            VStack(alignment: .leading, spacing: SettingsMetrics.rowTextSpacing) {
                Text(label)
                    .font(.system(size: SettingsMetrics.rowLabelSize, weight: .medium))
                    .foregroundColor(.irohaSumi)
                if let caption {
                    Text(caption)
                        .font(.system(size: SettingsMetrics.rowCaptionSize))
                        .foregroundColor(.irohaSumi3)
                }
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, SettingsMetrics.rowHPadding)
        .padding(.vertical, verticalPadding)
    }
}

/// 設定グループ内の区切り線（アイコン幅ぶん字下げする）
struct SettingsDivider: View {
    var leading: CGFloat = SettingsMetrics.dividerLeadingWithIcon

    var body: some View {
        Divider().padding(.leading, leading)
    }
}

/// セクション下に添える補足文
struct SettingsFootnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: SettingsMetrics.footnoteFontSize))
            .foregroundColor(.irohaSumi3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SettingsMetrics.footnoteHPadding)
            .padding(.top, SettingsMetrics.footnoteTopPadding)
    }
}
