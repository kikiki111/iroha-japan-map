//
//  PrivacyPolicyView.swift
//  Iroha
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                policySection(title: "基本方針", body: "いろは（以下「本アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めます。本アプリはユーザーの個人情報を収集・送信しません。")

                policySection(title: "データの保存", body: "本アプリで記録されるデータ（旅行記録、メモ、写真、設定など）は、すべてお使いの端末内にのみ保存されます。", bullets: [
                    "外部サーバーへのデータ送信は行いません",
                    "アカウント登録は不要です",
                    "第三者へのデータ提供は行いません",
                ])

                policySection(title: "写真へのアクセス", body: "旅行記録に写真を添付する機能を利用する場合、端末の写真ライブラリへのアクセス許可をお願いすることがあります。選択された写真はアプリ内にコピーされ、端末内にのみ保存されます。")

                policySection(title: "場所検索", body: "旅行場所の入力補助として Apple の地図検索サービスを利用しています。検索クエリは Apple に送信されますが、当社がこの情報を収集・保存することはありません。")

                policySection(title: "バックアップ", body: "バックアップ機能で書き出されるデータは JSON 形式のファイルです。このファイルの保存先・共有先はユーザー自身が選択します。なお、写真はバックアップに含まれません。")

                policySection(title: "分析・広告", body: "本アプリはアクセス解析ツール、広告 SDK、トラッキングツールを一切使用していません。")

                policySection(title: "お問い合わせ", body: "本ポリシーに関するお問い合わせは、App Store のアプリページからご連絡ください。")

                Text("最終更新日: 2026年4月29日")
                    .font(.system(size: 11))
                    .foregroundColor(.irohaSumi3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(20)
        }
        .background(Color.irohaWashi)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("プライバシーポリシー")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .tracking(1)
            }
        }
    }

    private func policySection(title: String, body: String, bullets: [String]? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.irohaSumi)
            Text(body)
                .font(.system(size: 13))
                .foregroundColor(.irohaSumi2)
            if let bullets {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(bullets, id: \.self) { item in
                        HStack(alignment: .top, spacing: 6) {
                            Text("・")
                                .font(.system(size: 13))
                                .foregroundColor(.irohaSumi3)
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundColor(.irohaSumi2)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
