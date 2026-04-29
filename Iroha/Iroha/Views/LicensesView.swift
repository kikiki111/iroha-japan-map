//
//  LicensesView.swift
//  Iroha
//

import SwiftUI

struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                licenseEntry(
                    name: "GeoJSON 都道府県データ",
                    copyright: "国土交通省 国土数値情報",
                    license: "国土数値情報利用約款に基づき使用"
                )
                licenseEntry(
                    name: "日本地図 SVG",
                    copyright: "© Geolonia Inc.",
                    license: "MIT License"
                )
            }
            .padding(20)
        }
        .background(Color.irohaWashi)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ライセンス")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .tracking(1)
            }
        }
    }

    private func licenseEntry(name: String, copyright: String, license: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.irohaSumi)
            Text(copyright)
                .font(.system(size: 13))
                .foregroundColor(.irohaSumi2)
            Text(license)
                .font(.system(size: 12))
                .foregroundColor(.irohaSumi3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.irohaCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.irohaWashi3, lineWidth: 0.5))
    }
}

#Preview {
    NavigationStack {
        LicensesView()
    }
}
