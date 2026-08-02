//
//  PrefectureDetailSheet.swift
//  Iroha
//
//  県詳細シート（タップで開く）

import SwiftUI
import SwiftData

/// 県詳細シート
struct PrefectureDetailSheet: View {
    let prefecture: Prefecture

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Visit.startDate, order: .reverse) private var allVisits: [Visit]

    @State private var showAddVisit = false
    @State private var editingVisit: Visit?
    @State private var selectedTrip: Trip?
    @State private var showDeleteConfirmation = false
    @State private var visitToDelete: Visit?
    @State private var browserSelection: PhotoFullscreenSelection?
    @State private var browserIndex: Int = 0
    @State private var showPhotoLoadError = false

    private var sortedVisits: [Visit] {
        allVisits.filter { $0.prefectureID == prefecture.id }
    }

    /// 旅行記録のみ（訪問回数・訪問履歴はこちらを使う）
    private var travelVisits: [Visit] {
        sortedVisits.filter { !$0.isResidence }
    }

    /// 居住記録のみ（新しい順）
    private var residenceVisits: [Visit] {
        sortedVisits.filter(\.isResidence)
    }

    private var visitCount: Int { travelVisits.count }

    private var allPhotoItems: [(visit: Visit, identifier: String, thumbnail: Data)] {
        sortedVisits.flatMap { visit in
            zip(visit.sortedPhotoFilenames, visit.sortedPhotoThumbnails).map { (visit, $0, $1) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    residenceSection
                    photoGallery
                    recordButtonsRow
                    visitList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddVisit) {
                VisitFormView(prefectures: Prefecture.all, prefecture: prefecture, editingVisit: nil)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $editingVisit) { visit in
                VisitFormView(prefectures: Prefecture.all, prefecture: prefecture, editingVisit: visit)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailSheet(trip: trip, prefectures: Prefecture.all) { visit in
                    selectedTrip = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editingVisit = visit
                    }
                }
                .presentationDetents([.large])
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .alert(
                visitToDelete?.isResidence == true ? "住んだ記録を削除しますか？" : "旅行記録を削除しますか？",
                isPresented: $showDeleteConfirmation
            ) {
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
            if let selection = browserSelection {
                let pageCount = max(selection.identifiers.count, selection.thumbnails.count)
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()

                    TabView(selection: $browserIndex) {
                        ForEach(0..<pageCount, id: \.self) { i in
                            browserPhotoView(selection: selection, at: i)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: pageCount > 1 ? .always : .never))

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) { browserSelection = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.white, Color.black.opacity(0.45))
                            .padding(.trailing, 16)
                            .padding(.top, 12)
                    }
                    .accessibilityLabel("写真を閉じる")
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: browserSelection != nil)
        .interactiveDismissDisabled(browserSelection != nil)
    }

    @ViewBuilder
    private func browserPhotoView(selection: PhotoFullscreenSelection, at index: Int) -> some View {
        let pageCount = max(selection.identifiers.count, selection.thumbnails.count)
        VStack(spacing: 0) {
            Color.clear.frame(height: 30)
            Group {
                if index < selection.identifiers.count,
                   let img = VisitPhotoStore.loadFullImage(for: selection.identifiers[index], in: selection.visit) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else if index < selection.thumbnails.count,
                          let img = UIImage(data: selection.thumbnails[index]) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Color.black
                }
            }
            if pageCount > 1 {
                Color.clear.frame(height: 30)
            }
        }
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
                NurikakeNumber(value: visitCount, fontSize: 44,
                              ratio: min(Double(visitCount) / 5.0, 1.0))
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

    // MARK: - Residence section

    /// 居住記録は訪問履歴とは別枠で、県名のすぐ下に期間を並べる。
    @ViewBuilder
    private var residenceSection: some View {
        let residences = residenceVisits
        if !residences.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                // 「写真」セクション見出しと同じ書式に揃える
                Text("住んでいた期間")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.irohaSumi3)
                    .tracking(1)
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(Array(residences.enumerated()), id: \.element.id) { index, visit in
                        Button {
                            editingVisit = visit
                        } label: {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    // 訪問カードの日付 (15pt bold) と同じ書式。色だけ金茶。
                                    Text(visit.residencePeriodText)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.irohaSumikaDk)
                                    HStack(spacing: 6) {
                                        if let duration = visit.residenceDurationText {
                                            Text(duration)
                                                .font(.system(size: 11))
                                                .foregroundColor(.irohaSumi3)
                                        }
                                        if visit.hasLocation {
                                            Text(visit.location)
                                                .font(.system(size: 11))
                                                .foregroundColor(.irohaSumi2)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.irohaSumi3.opacity(0.5))
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < residences.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(Color.irohaWashi2.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.irohaWashi3, lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
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
                        ForEach(Array(items.enumerated()), id: \.element.identifier) { _, item in
                            if let uiImage = UIImage(data: item.thumbnail) {
                                Button {
                                    openPhoto(identifier: item.identifier, in: item.visit)
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

    // MARK: - Record buttons

    private var todayVisit: Visit? {
        let calendar = Calendar.current
        return travelVisits.first { calendar.isDateInToday($0.startDate) }
    }

    private var recordButtonsRow: some View {
        HStack(spacing: 8) {
            todayRecordButton
            otherDayRecordButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var todayRecordButton: some View {
        if let existing = todayVisit {
            Button {
                editingVisit = existing
            } label: {
                recordButtonLabel(
                    icon: "pencil.circle.fill",
                    title: "今日の記録を編集",
                    foreground: .white,
                    background: Color.irohaFuji.opacity(0.7),
                    strokeColor: nil
                )
            }
        } else {
            Button {
                let visit = Visit(
                    prefectureName: prefecture.name,
                    prefectureID: prefecture.id,
                    startDate: Date()
                )
                modelContext.insert(visit)
                try? modelContext.save()
            } label: {
                recordButtonLabel(
                    icon: "plus.circle.fill",
                    title: "今日を記録",
                    foreground: .white,
                    background: Color.irohaFuji,
                    strokeColor: nil
                )
            }
        }
    }

    private var otherDayRecordButton: some View {
        Button {
            showAddVisit = true
        } label: {
            recordButtonLabel(
                icon: "calendar.badge.plus",
                title: "他の日を記録",
                foreground: .irohaFujiDk,
                background: Color.irohaFujiLt.opacity(0.25),
                strokeColor: Color.irohaFujiLt
            )
        }
    }

    private func recordButtonLabel(
        icon: String,
        title: String,
        foreground: Color,
        background: Color,
        strokeColor: Color?
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(foreground)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 22)
        .padding(.vertical, 10)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            if let strokeColor {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, lineWidth: 1)
            }
        }
    }

    // MARK: - Visit list

    private var visitList: some View {
        let visits = travelVisits
        return LazyVStack(spacing: 0) {
            ForEach(Array(visits.enumerated()), id: \.element.id) { index, visit in
                visitCard(visit: visit, index: index)
                    .padding(.horizontal, 20)
                if index < visits.count - 1 {
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

            if let thumbnailData = visit.sortedPhotoThumbnails.first,
               let uiImage = UIImage(data: thumbnailData) {
                Button {
                    openVisitPhotos(visit)
                } label: {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        let count = visit.totalPhotoCount
                        if count > 1 {
                            Text("+\(count - 1)")
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
            openTripDetail(for: visit)
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

    private func openTripDetail(for visit: Visit) {
        let allTrips = TripDetector.detect(from: Array(allVisits))
        if let trip = allTrips.first(where: { $0.visits.contains { $0.id == visit.id } }) {
            selectedTrip = trip
        } else {
            editingVisit = visit
        }
    }

    // MARK: - Helpers

    private func spacedKana(_ kana: String) -> String {
        kana.map { String($0) }.joined(separator: " ")
    }

    private func openPhoto(identifier: String, in visit: Visit) {
        let identifiers = visit.sortedPhotoFilenames
        guard let initialIndex = identifiers.firstIndex(of: identifier) else {
            showPhotoLoadError = true
            return
        }
        browserIndex = initialIndex
        browserSelection = PhotoFullscreenSelection(
            visit: visit,
            identifiers: identifiers,
            thumbnails: visit.sortedPhotoThumbnails,
            initialIndex: initialIndex
        )
    }

    private func openVisitPhotos(_ visit: Visit) {
        let identifiers = visit.sortedPhotoFilenames
        guard !identifiers.isEmpty else {
            showPhotoLoadError = true
            return
        }
        browserIndex = 0
        browserSelection = PhotoFullscreenSelection(
            visit: visit,
            identifiers: identifiers,
            thumbnails: visit.sortedPhotoThumbnails,
            initialIndex: 0
        )
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
        .modelContainer(for: [Visit.self], inMemory: true)
}
