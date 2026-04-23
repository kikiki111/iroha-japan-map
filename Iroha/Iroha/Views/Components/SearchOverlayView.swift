//
//  SearchOverlayView.swift
//  Iroha
//
//  県名検索オーバーレイ

import SwiftUI

/// 県名検索オーバーレイ
struct SearchOverlayView: View {
    let prefectures: [Prefecture]
    @Binding var isPresented: Bool
    var onSelect: (Prefecture) -> Void

    @State private var searchText = ""
    @FocusState private var isFocused: Bool

    private var searchResults: [Prefecture] {
        guard !searchText.isEmpty else { return [] }
        let q = searchText.lowercased()
        return prefectures
            .filter { $0.name.contains(q) || $0.nameKana.contains(q) }
            .sorted { $0.id < $1.id }
            .prefix(8)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(.irohaSumi3)
                TextField("県名で検索", text: $searchText)
                    .font(.system(size: 15, weight: .medium))
                    .focused($isFocused)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.irohaSumi3)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.irohaFujiLt, lineWidth: 0.5)
            )
            .shadow(color: Color.irohaFuji.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // Results
            if !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults) { pref in
                        Button {
                            onSelect(pref)
                        } label: {
                            HStack(spacing: 10) {
                                // Nurikake dot
                                Circle()
                                    .fill(Color.irohaWashi3)
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        pref.isVisited ?
                                        Circle()
                                            .fill(Color.irohaFujiDk)
                                            .mask(
                                                VStack(spacing: 0) {
                                                    Rectangle()
                                                        .frame(height: 5)
                                                    Spacer(minLength: 0)
                                                }
                                                .frame(height: 10)
                                            )
                                        : nil
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pref.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.irohaSumi)
                                    Text(pref.isVisited ? "\(pref.visitCount)回訪問" : "未訪問")
                                        .font(.system(size: 12))
                                        .foregroundColor(.irohaSumi3)
                                }

                                Spacer()

                                Text(pref.region.localizedName)
                                    .font(.system(size: 12, design: .serif))
                                    .foregroundColor(.irohaSumi3)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }

                        if pref.id != searchResults.last?.id {
                            Divider().padding(.leading, 34)
                        }
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.irohaWashi3, lineWidth: 0.5))
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }

            Spacer()
        }
        .background(Color.irohaWashi.opacity(0.3))
        .contentShape(Rectangle())
        .onTapGesture {
            if searchText.isEmpty {
                withAnimation { isPresented = false }
            }
        }
        .onAppear { isFocused = true }
    }
}
