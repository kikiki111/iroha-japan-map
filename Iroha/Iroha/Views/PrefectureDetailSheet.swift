//
//  PrefectureDetailSheet.swift
//  Iroha
//
//  県詳細シート（タップで開く）

import SwiftUI
import SwiftData

/// 県詳細シート
struct PrefectureDetailSheet: View {
    @Bindable var prefecture: Prefecture

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Prefecture.id) private var allPrefectures: [Prefecture]

    @State private var showAddVisit = false
    @State private var editingVisit: Visit?
    @State private var showDeleteConfirmation = false
    @State private var visitToDelete: Visit?
    @State private var fullScreenPhoto: UIImage?
    @State private var showPhotoLoadError = false

    private var sortedVisits: [Visit] {
        prefecture.visits.sorted { $0.startDate > $1.startDate }
    }

    private var allPhotoItems: [(filename: String, thumbnail: Data)] {
        sortedVisits.flatMap { visit in
            zip(visit.allPhotoFilenames, visit.allPhotoThumbnails).map { ($0, $1) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    photoGallery
                    quickRecordButton
                    addDetailButton
                    visitList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddVisit) {
                VisitFormView(prefectures: allPrefectures, prefecture: prefecture, editingVisit: nil)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $editingVisit) { visit in
                VisitFormView(prefectures: allPrefectures, prefecture: prefecture, editingVisit: visit)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .alert("旅行記録を削除しますか？", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    if let visit = visitToDelete {
                        let filenames = visit.allPhotoFilenames
                        modelContext.delete(visit)
                        if (try? modelContext.save()) != nil {
                            for filename in filenames {
                                PhotoStorageManager.delete(filename: filename)
                            }
                        }
                    }
                }
            } message: {
                Text("この操作は元に戻せません")
            }
            .alert("写真を読み込めませんでした", isPresented: $showPhotoLoadError) {
                Button("OK") {}
            } message: {
                Text("写真ファイルが見つからないか、開けない状態です。")
            }
        }
        .overlay {
            if let photo = fullScreenPhoto {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) { fullScreenPhoto = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white, .white.opacity(0.3))
                            }
                            .padding(16)
                            .accessibilityLabel("写真を閉じる")
                        }
                        Spacer()
                    }
                }
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) { fullScreenPhoto = nil }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: fullScreenPhoto != nil)
        .interactiveDismissDisabled(fullScreenPhoto != nil)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                // 読み仮名
                Text(spacedKana(prefecture.nameKana))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.irohaSumi3)
                    .tracking(2.5)

                // 県名
                Text(prefecture.name)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.irohaSumi)

                // 地方名
                Text("\(prefecture.region.localizedName)地方")
                    .font(.system(size: 13))
                    .foregroundColor(.irohaSumi3)
            }

            Spacer()

            VStack(spacing: 3) {
                // 訪問数（塗りかけ）
                NurikakeNumber(value: prefecture.visitCount, fontSize: 44,
                              ratio: min(Double(prefecture.visitCount) / 5.0, 1.0))
                Text("回旅行")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.irohaSumi3)
                    .tracking(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
    }

    // MARK: - Photo gallery

    @ViewBuilder
    private var photoGallery: some View {
        let items = allPhotoItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("写真")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.irohaSumi3)
                        .tracking(1)
                    Spacer()
                    Text("\(items.count)枚")
                        .font(.system(size: 12))
                        .foregroundColor(.irohaSumi3)
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.element.filename) { _, item in
                            if let uiImage = UIImage(data: item.thumbnail) {
                                Button {
                                    openPhoto(filename: item.filename)
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 10)
            .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
        }
    }

    // MARK: - Quick record button

    private var todayVisit: Visit? {
        let calendar = Calendar.current
        return prefecture.visits.first { calendar.isDateInToday($0.startDate) }
    }

    private var quickRecordButton: some View {
        Group {
            if let existing = todayVisit {
                Button {
                    editingVisit = existing
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("今日の記録を編集")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(Date().formatted(.dateTime.month().day().locale(Locale(identifier: "ja_JP"))))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.irohaFuji.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Button {
                    let visit = Visit(prefectureName: prefecture.name, startDate: Date())
                    visit.prefecture = prefecture
                    modelContext.insert(visit)
                    try? modelContext.save()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        Text("今日の旅行を記録")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(Date().formatted(.dateTime.month().day().locale(Locale(identifier: "ja_JP"))))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.irohaFuji)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Add detail button

    private var addDetailButton: some View {
        HStack {
            Spacer()
            Button {
                showAddVisit = true
            } label: {
                Text("＋ 詳細で追加")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.irohaFujiDk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.irohaFujiLt.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.irohaFujiLt, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Visit list

    private var visitList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(sortedVisits.enumerated()), id: \.element.id) { index, visit in
                visitCard(visit: visit, index: index)
                    .padding(.horizontal, 20)
                if index < sortedVisits.count - 1 {
                    Divider()
                        .padding(.leading, 40)
                        .padding(.trailing, 20)
                }
            }
        }
        .padding(.top, 6)
    }

    private func visitCard(visit: Visit, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Nurikake dot
            Circle()
                .fill(Color.visitColor(count: index + 1))
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(visit.startDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                        .font(.system(size: 15, weight: .bold))

                    if visit.effectiveTag != .none {
                        VisitTagBadge(tag: visit.effectiveTag)
                    }
                    if visit.effectiveMood != .none {
                        VisitMoodBadge(mood: visit.effectiveMood)
                    }
                    VisitTransportBadge(transports: visit.effectiveTransports)
                    VisitCompanionBadge(companions: visit.companions)
                }

                if visit.hasLocation {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                            .foregroundColor(.irohaSumi3)
                        Text(visit.location)
                            .font(.system(size: 12))
                            .foregroundColor(.irohaSumi2)
                            .lineLimit(1)
                    }
                }

                if !visit.tripName.isEmpty {
                    Text(visit.tripName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.irohaFuji)
                }

                if !visit.note.isEmpty {
                    Text(visit.note)
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi2)
                        .lineHeight(1.5)
                } else {
                    Text("メモなし")
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi3)
                }
            }

            Spacer()

            if let thumbnailData = visit.allPhotoThumbnails.first,
               let uiImage = UIImage(data: thumbnailData) {
                Button {
                    if let filename = visit.allPhotoFilenames.first {
                        openPhoto(filename: filename)
                    }
                } label: {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        if visit.allPhotoFilenames.count > 1 {
                            Text("+\(visit.allPhotoFilenames.count - 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            editingVisit = visit
        }
        .contextMenu {
            Button {
                editingVisit = visit
            } label: {
                Label("編集", systemImage: "pencil")
            }
            Button(role: .destructive) {
                visitToDelete = visit
                showDeleteConfirmation = true
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func spacedKana(_ kana: String) -> String {
        kana.map { String($0) }.joined(separator: " ")
    }

    private func openPhoto(filename: String) {
        if let image = PhotoStorageManager.loadImage(filename: filename) {
            fullScreenPhoto = image
        } else {
            showPhotoLoadError = true
        }
    }
}

// MARK: - Text line height extension

extension View {
    func lineHeight(_ multiplier: CGFloat) -> some View {
        self.lineSpacing((multiplier - 1) * 13)
    }
}

// MARK: - Preview

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            PrefectureDetailSheet(
                prefecture: Prefecture(
                    id: 26, name: "京都府", nameKana: "きょうとふ",
                    region: .kinki, latitude: 35.0, longitude: 135.7,
                    distanceFromTokyo: 453
                )
            )
            .presentationDetents([.fraction(0.7)])
        }
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
