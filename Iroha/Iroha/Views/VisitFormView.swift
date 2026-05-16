//
//  VisitFormView.swift
//  Iroha
//

import SwiftUI
import SwiftData
import PhotosUI

struct VisitFormView: View {
    let prefectures: [Prefecture]
    let prefecture: Prefecture?
    let editingVisit: Visit?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPrefectureName = ""
    @State private var visitDate = Date()
    @State private var endDate = Date()
    @State private var selectedTag: VisitTag = .none
    @State private var selectedMood: VisitMood = .none
    @State private var selectedTransports: Set<VisitTransport> = []
    @State private var memo = ""
    @State private var tripName = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var photoFilenameMap: [String?] = []
    @State private var removedFilenames: [String] = []
    @State private var companions: [String] = []
    @State private var companionInput = ""
    @State private var location = ""
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var showDeleteConfirmation = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSelectingFromSuggestion = false
    @State private var didPopulate = false
    @FocusState private var locationFieldFocused: Bool
    @StateObject private var locationCompleter = LocationSearchCompleter()

    @Query(sort: \Visit.startDate) private var allVisits: [Visit]
    @State private var expandedSection: FormSection?
    @State private var prefectureSearch = ""
    @State private var activeDateField: DateField = .start
    @State private var pickerRefreshId = 0

    private var isEditing: Bool { editingVisit != nil }
    private var isPrefectureLocked: Bool { prefecture != nil }
    private let maxPhotoCount = 10

    private enum FormSection: Hashable {
        case prefecture, date, tag, location, transport, companion, mood, photo
    }

    private enum DateField {
        case start, end
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    prefectureRow
                    divider
                    tagRow
                    divider
                    dateRow
                    divider
                    locationRow
                    divider
                    photoRow
                    divider
                    transportRow
                    divider
                    companionRow
                    divider
                    moodRow
                    divider
                    tripNameRow
                    divider
                    memoRow

                    if isEditing {
                        deleteButton
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.irohaWashi)
            .navigationTitle("旅の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.irohaFujiDk)
                        .disabled(selectedPrefectureName.isEmpty)
                }
            }
            .onAppear { populateFields() }
            .alert("この記録を削除しますか？", isPresented: $showDeleteConfirmation) {
                Button("削除", role: .destructive) { deleteVisit() }
                Button("キャンセル", role: .cancel) { }
            }
            .alert("保存に失敗しました", isPresented: $showSaveError) {
                Button("OK") {}
            } message: {
                Text(saveErrorMessage)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.irohaWashi)
    }

    // MARK: - Rows

    private var prefectureRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "mappin.circle",
                label: "都道府県",
                value: selectedPrefectureName.isEmpty ? "選択してください" : selectedPrefectureName,
                valueColor: selectedPrefectureName.isEmpty ? .irohaSumi3 : .irohaSumi,
                section: isPrefectureLocked ? nil : .prefecture
            )

            if expandedSection == .prefecture {
                prefecturePickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var dateRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "calendar",
                label: "旅行日",
                value: formattedDateSummary,
                section: .date
            )

            if expandedSection == .date {
                datePickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: expandedSection) { _, newSection in
            if newSection == .date { activeDateField = .start }
        }
        .onChange(of: activeDateField) { _, newField in
            guard newField == .end else { return }
            // 帰着日カレンダーが開始日の年月で開くように、年月が違っていたら開始日に揃える
            let calendar = Calendar.current
            let visitYM = calendar.dateComponents([.year, .month], from: visitDate)
            let endYM = calendar.dateComponents([.year, .month], from: endDate)
            if visitYM.year != endYM.year || visitYM.month != endYM.month {
                endDate = visitDate
            }
        }
    }

    private var tagRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "tag",
                label: "旅行スタイル",
                value: selectedTag == .none ? "未選択" : selectedTag.displayName,
                valueColor: selectedTag == .none ? .irohaSumi3 : selectedTag.foregroundColor,
                section: .tag
            )

            if expandedSection == .tag {
                tagPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var transportRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.irohaSumi3)
                    .frame(width: 24)

                Text("移動手段")
                    .font(.system(size: 15))
                    .foregroundColor(.irohaSumi2)

                Spacer()

                if selectedTransports.isEmpty {
                    Text("未選択")
                        .font(.system(size: 15))
                        .foregroundColor(.irohaSumi3)
                } else {
                    HStack(spacing: 4) {
                        ForEach(Array(selectedTransports).sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { t in
                            Image(systemName: t.iconName)
                                .font(.system(size: 13))
                                .foregroundColor(t.foregroundColor)
                        }
                    }
                }

                chevron(for: .transport)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture { toggle(.transport) }

            if expandedSection == .transport {
                transportPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var moodRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                    .foregroundColor(.irohaSumi3)
                    .frame(width: 24)

                Text("ムード")
                    .font(.system(size: 15))
                    .foregroundColor(.irohaSumi2)

                Spacer()

                if selectedMood == .none {
                    Text("未選択")
                        .font(.system(size: 15))
                        .foregroundColor(.irohaSumi3)
                } else {
                    Text(selectedMood.displayName)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(selectedMood.foregroundColor)
                        .clipShape(Circle())
                }

                chevron(for: .mood)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture { toggle(.mood) }

            if expandedSection == .mood {
                moodPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var photoRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 16))
                    .foregroundColor(.irohaSumi3)
                    .frame(width: 24)

                Text("写真")
                    .font(.system(size: 15))
                    .foregroundColor(.irohaSumi2)

                Spacer()

                if photoImages.isEmpty {
                    Text("追加する")
                        .font(.system(size: 15))
                        .foregroundColor(.irohaSumi3)
                } else {
                    HStack(spacing: 4) {
                        ForEach(Array(photoImages.prefix(4).enumerated()), id: \.offset) { _, img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 28, height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        if photoImages.count > 4 {
                            Text(verbatim: "+\(photoImages.count - 4)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.irohaSumi3)
                        }
                    }
                }

                chevron(for: .photo)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture { toggle(.photo) }

            if expandedSection == .photo {
                photoPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var locationRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "mappin",
                label: "場所",
                value: location.isEmpty ? "未入力" : location,
                valueColor: location.isEmpty ? .irohaSumi3 : .irohaSumi,
                section: .location
            )

            if expandedSection == .location {
                locationContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var locationContent: some View {
        VStack(spacing: 8) {
            TextField("場所名（例：道後温泉）", text: $location)
                .focused($locationFieldFocused)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.irohaCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .submitLabel(.done)
                .onSubmit {
                    locationFieldFocused = false
                    locationCompleter.results = []
                    expandedSection = nil
                }
                .onChange(of: location) { _, newValue in
                    if isSelectingFromSuggestion { return }
                    locationLatitude = nil
                    locationLongitude = nil
                    locationCompleter.search(newValue)
                }

            if !locationCompleter.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(locationCompleter.results.prefix(5).enumerated()), id: \.offset) { _, result in
                        Button {
                            selectLocation(result)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(.irohaSumi)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 11))
                                        .foregroundColor(.irohaSumi3)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                selectLocation(result)
                            }
                        )
                        Divider().padding(.leading, 12)
                    }
                }
                .background(Color.irohaCard)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if locationLatitude != nil {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.irohaFuji)
                    Text("位置情報あり")
                        .font(.system(size: 11))
                        .foregroundColor(.irohaSumi3)
                    Spacer()
                    Button {
                        locationLatitude = nil
                        locationLongitude = nil
                    } label: {
                        Text("位置情報を削除")
                            .font(.system(size: 11))
                            .foregroundColor(.irohaSumi3)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    @MainActor
    private func selectLocation(_ suggestion: PlaceSuggestion) {
        if isSelectingFromSuggestion { return }
        isSelectingFromSuggestion = true
        locationFieldFocused = false
        location = suggestion.title
        locationLatitude = suggestion.latitude
        locationLongitude = suggestion.longitude
        locationCompleter.results = []
        expandedSection = nil
        Task { @MainActor in
            isSelectingFromSuggestion = false
        }
    }

    private var companionRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.irohaSumi3)
                    .frame(width: 24)

                Text("同行者")
                    .font(.system(size: 15))
                    .foregroundColor(.irohaSumi2)

                Spacer()

                if companions.isEmpty {
                    Text("未入力")
                        .font(.system(size: 15))
                        .foregroundColor(.irohaSumi3)
                } else {
                    Text(companions.joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi)
                        .lineLimit(1)
                }

                chevron(for: .companion)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .onTapGesture { toggle(.companion) }

            if expandedSection == .companion {
                companionContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var companionSuggestions: [String] {
        let all = Set(allVisits.flatMap { $0.companions })
        let current = Set(companions)
        let available = all.subtracting(current)
        if companionInput.isEmpty { return Array(available).sorted() }
        return available.filter { $0.localizedCaseInsensitiveContains(companionInput) }.sorted()
    }

    private func addCompanion() {
        let name = companionInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !companions.contains(name) else { return }
        companions.append(name)
        companionInput = ""
    }

    private var companionContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("名前を入力", text: $companionInput)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.irohaCard)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit { addCompanion() }

                Button {
                    addCompanion()
                } label: {
                    Text("追加")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(companionInput.trimmingCharacters(in: .whitespaces).isEmpty ? Color.irohaSumi3 : Color.irohaFujiDk)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(companionInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !companionSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("候補")
                        .font(.system(size: 11))
                        .foregroundColor(.irohaSumi3)
                    FlowLayout(spacing: 6) {
                        ForEach(Array(companionSuggestions.prefix(8)), id: \.self) { name in
                            Button {
                                companions.append(name)
                                companionInput = ""
                            } label: {
                                Text(name)
                                    .font(.system(size: 13))
                                    .foregroundColor(.irohaFujiDk)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.irohaFuji.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            if !companions.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(companions, id: \.self) { name in
                        HStack(spacing: 4) {
                            Text(name)
                                .font(.system(size: 13))
                            Button {
                                companions.removeAll { $0 == name }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.irohaSumi3)
                            }
                        }
                        .foregroundColor(.irohaSumi)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.irohaWashi2)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var tripNameRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "suitcase")
                .font(.system(size: 16))
                .foregroundColor(.irohaSumi3)
                .frame(width: 24, alignment: .top)
                .padding(.top, 2)

            TextField("旅行名（例：九州一周旅行）", text: $tripName)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var memoRow: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 16))
                .foregroundColor(.irohaSumi3)
                .frame(width: 24)
                .padding(.top, 10)

            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("旅の思い出を残しておこう…")
                        .font(.system(size: 15))
                        .foregroundColor(.irohaSumi3.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $memo)
                    .font(.system(size: 15))
                    .frame(minHeight: 60, maxHeight: 160)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    // MARK: - Expanded contents

    private var prefecturePickerContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.irohaSumi3)
                TextField("県名で検索", text: $prefectureSearch)
                    .font(.system(size: 14))
                if !prefectureSearch.isEmpty {
                    Button {
                        prefectureSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.irohaSumi3)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.irohaCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            ForEach(Region.allCases) { region in
                let regionPrefs = filteredPrefectures(for: region)
                if !regionPrefs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(region.localizedName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.irohaSumi3)
                            .tracking(1)

                        FlowLayout(spacing: 6) {
                            ForEach(regionPrefs) { pref in
                                let isSelected = pref.name == selectedPrefectureName
                                Button {
                                    selectedPrefectureName = pref.name
                                    prefectureSearch = ""
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        expandedSection = nil
                                    }
                                } label: {
                                    Text(pref.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(isSelected ? .white : .irohaSumi)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.irohaFujiDk : Color.irohaWashi2)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(isSelected ? Color.irohaFujiDk : Color.irohaWashi3, lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var datePickerContent: some View {
        VStack(spacing: 8) {
            dateFieldRow(field: .start, label: "開始日", date: visitDate)
            if activeDateField == .start {
                DatePicker(
                    "開始日",
                    selection: $visitDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.irohaFuji)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .labelsHidden()
                .id(pickerRefreshId)
                .onChange(of: visitDate) { oldDate, newDate in
                    let calendar = Calendar.current
                    if newDate > endDate {
                        let duration = calendar.dateComponents([.day], from: oldDate, to: endDate).day ?? 0
                        endDate = calendar.date(byAdding: .day, value: max(duration, 0), to: newDate) ?? newDate
                    }
                    // 年月ホイール操作（年・月のみ変更）では切替しない。日付グリッドで日をタップした時のみ次へ進む
                    let oldComp = calendar.dateComponents([.year, .month, .day], from: oldDate)
                    let newComp = calendar.dateComponents([.year, .month, .day], from: newDate)
                    let isDayLevelChange = oldComp.year == newComp.year
                        && oldComp.month == newComp.month
                        && oldComp.day != newComp.day
                    if isDayLevelChange {
                        activeDateField = .end
                    }
                }

                pickerDoneLink
            }

            dateFieldRow(field: .end, label: "帰着日", date: endDate)
            if activeDateField == .end {
                DatePicker(
                    "帰着日",
                    selection: $endDate,
                    in: visitDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.irohaFuji)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .labelsHidden()
                .id(pickerRefreshId)
                .onChange(of: endDate) { oldDate, newDate in
                    // 年月ホイール操作では閉じない。日付グリッドで日をタップした時のみ旅行日セクションを閉じる
                    let calendar = Calendar.current
                    let oldComp = calendar.dateComponents([.year, .month, .day], from: oldDate)
                    let newComp = calendar.dateComponents([.year, .month, .day], from: newDate)
                    let isDayLevelChange = oldComp.year == newComp.year
                        && oldComp.month == newComp.month
                        && oldComp.day != newComp.day
                    if isDayLevelChange {
                        expandedSection = nil
                    }
                }

                pickerDoneLink
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var pickerDoneLink: some View {
        HStack {
            Spacer()
            Button {
                pickerRefreshId += 1
                // 日付タップ時と同じ進行を提供:
                // 開始日 picker → 帰着日 picker、帰着日 picker → セクション閉じる
                if activeDateField == .start {
                    activeDateField = .end
                } else {
                    expandedSection = nil
                }
            } label: {
                Text("完了")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.irohaFuji)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
            }
        }
    }

    private func dateFieldRow(field: DateField, label: String, date: Date) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.irohaSumi2)
            Spacer()
            Text(date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                .font(.system(size: 15))
                .foregroundColor(activeDateField == field ? .irohaFuji : .irohaSumi)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { activeDateField = field }
    }

    private var tagPickerContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(VisitTag.selectableCases, id: \.rawValue) { tag in
                Button {
                    selectedTag = selectedTag == tag ? .none : tag
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tag.iconName)
                            .font(.system(size: 13))
                        Text(tag.displayName)
                            .font(.system(size: 14, weight: selectedTag == tag ? .bold : .medium))
                    }
                    .foregroundColor(selectedTag == tag ? tag.foregroundColor : .irohaSumi3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTag == tag ? tag.backgroundColor : Color.irohaWashi2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedTag == tag ? tag.foregroundColor.opacity(0.3) : Color.irohaWashi3, lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var transportPickerContent: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(VisitTransport.selectable, id: \.rawValue) { transport in
                let isSelected = selectedTransports.contains(transport)
                Button {
                    if isSelected {
                        selectedTransports.remove(transport)
                    } else {
                        selectedTransports.insert(transport)
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: transport.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? transport.foregroundColor : .irohaSumi3)
                        Text(transport.displayName)
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? transport.foregroundColor : .irohaSumi3)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .padding(.vertical, 8)
                    .background(isSelected ? transport.backgroundColor : Color.irohaWashi2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? transport.foregroundColor.opacity(0.5) : Color.irohaWashi3, lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var moodPickerContent: some View {
        HStack(spacing: 0) {
            ForEach(VisitMood.selectable, id: \.rawValue) { mood in
                Button {
                    selectedMood = selectedMood == mood ? .none : mood
                } label: {
                    VStack(spacing: 3) {
                        Text(mood.displayName)
                            .font(.system(size: 16, weight: selectedMood == mood ? .bold : .medium, design: .serif))
                            .foregroundColor(selectedMood == mood ? .white : mood.foregroundColor)
                            .frame(width: 36, height: 36)
                            .background(selectedMood == mood ? mood.foregroundColor : mood.backgroundColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(
                                    mood.foregroundColor.opacity(selectedMood == mood ? 1 : 0.3),
                                    lineWidth: selectedMood == mood ? 2 : 0.5
                                )
                            )
                        Text(mood.label)
                            .font(.system(size: 9))
                            .foregroundColor(selectedMood == mood ? mood.foregroundColor : .irohaSumi3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var remainingPhotoSlots: Int {
        max(0, maxPhotoCount - photoImages.count)
    }

    private var photoPickerContent: some View {
        VStack(spacing: 8) {
            if !photoImages.isEmpty {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(Array(photoImages.enumerated()), id: \.offset) { index, image in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    removePhoto(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white, .black.opacity(0.5))
                                }
                                .padding(4)
                            }
                    }
                }
            }
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: max(1, remainingPhotoSlots), matching: .images) {
                Label(remainingPhotoSlots > 0 ? "写真を追加" : "写真は10枚まで", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 14))
                    .foregroundColor(remainingPhotoSlots > 0 ? .irohaFujiDk : .irohaSumi3)
            }
            .disabled(remainingPhotoSlots == 0)
            .onChange(of: selectedPhotos) { _, items in
                loadSelectedPhotos(items)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Delete button

    private var deleteButton: some View {
        Button("この記録を削除", role: .destructive) {
            showDeleteConfirmation = true
        }
        .font(.system(size: 15))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.top, 16)
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider()
            .background(Color.irohaSumi.opacity(0.07))
            .padding(.leading, 58)
    }

    private func rowHeader(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .irohaSumi,
        section: FormSection?
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.irohaSumi3)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.irohaSumi2)

            Spacer()

            Text(value)
                .font(.system(size: 15))
                .foregroundColor(valueColor)

            if let section {
                chevron(for: section)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            if let section {
                toggle(section)
            }
        }
    }

    private func chevron(for section: FormSection) -> some View {
        Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.irohaSumi3)
    }

    private func toggle(_ section: FormSection) {
        withAnimation(.easeInOut(duration: 0.25)) {
            expandedSection = expandedSection == section ? nil : section
        }
    }

    private var formattedDateSummary: String {
        let fmt = { (d: Date) in
            d.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP")))
        }
        if !Calendar.current.isDate(visitDate, inSameDayAs: endDate) {
            return "\(fmt(visitDate)) → \(fmt(endDate))"
        }
        return fmt(visitDate)
    }

    private func filteredPrefectures(for region: Region) -> [Prefecture] {
        let regionPrefs = prefectures.filter { $0.region == region }
        if prefectureSearch.isEmpty { return regionPrefs }
        return regionPrefs.filter { $0.name.contains(prefectureSearch) || $0.nameKana.contains(prefectureSearch) }
    }

    // MARK: - Data operations

    private func populateFields() {
        guard !didPopulate else { return }
        didPopulate = true
        if let visit = editingVisit {
            selectedPrefectureName = visit.prefectureName
            visitDate = visit.startDate
            endDate = visit.effectiveEndDate
            selectedTag = visit.effectiveTag
            selectedMood = visit.effectiveMood
            selectedTransports = Set(visit.effectiveTransports)
            memo = visit.note
            tripName = visit.tripName
            companions = visit.companions
            location = visit.location
            locationLatitude = visit.locationLatitude
            locationLongitude = visit.locationLongitude
            // 識別子は新写真なら VisitPhoto.id.uuidString、未移行 legacy なら filename
            for identifier in visit.sortedPhotoFilenames {
                if let image = VisitPhotoStore.loadFullImage(for: identifier, in: visit) {
                    photoImages.append(image)
                    photoFilenameMap.append(identifier)
                }
            }
        } else if let pref = prefecture {
            selectedPrefectureName = pref.name
        } else if !isPrefectureLocked && editingVisit == nil {
            expandedSection = .prefecture
        }
    }

    private func removePhoto(at index: Int) {
        if index < photoFilenameMap.count, let filename = photoFilenameMap[index] {
            removedFilenames.append(filename)
        }
        if index < photoFilenameMap.count {
            photoFilenameMap.remove(at: index)
        }
        photoImages.remove(at: index)
    }

    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        let slots = max(0, maxPhotoCount - photoImages.count)
        let toLoad = Array(items.prefix(slots))
        selectedPhotos.removeAll()
        guard !toLoad.isEmpty else { return }

        Task { @MainActor in
            var loadedImages: [UIImage] = []
            for item in toLoad {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            }

            let remaining = max(0, maxPhotoCount - photoImages.count)
            for image in loadedImages.prefix(remaining) {
                photoImages.append(image)
                photoFilenameMap.append(nil)
            }
        }
    }

    private func save() {
        let computedEndDate: Date? = {
            Calendar.current.isDate(endDate, inSameDayAs: visitDate) ? nil : endDate
        }()
        let resolvedPrefectureID = Prefecture.by(name: selectedPrefectureName)?.id ?? 0

        // メタデータ更新 (Visit を確保)
        let visit: Visit
        if let existing = editingVisit {
            visit = existing
            visit.prefectureName = selectedPrefectureName
            visit.prefectureID = resolvedPrefectureID
            visit.startDate = visitDate
            visit.endDate = computedEndDate
            visit.tag = selectedTag
            visit.mood = selectedMood
            visit.transports = selectedTransports.map(\.rawValue)
            visit.note = memo
            visit.tripName = tripName
            visit.companions = companions
            visit.location = location
            visit.locationLatitude = locationLatitude
            visit.locationLongitude = locationLongitude
        } else {
            let newVisit = Visit(
                prefectureName: selectedPrefectureName,
                prefectureID: resolvedPrefectureID,
                startDate: visitDate,
                endDate: computedEndDate,
                note: memo,
                tag: selectedTag
            )
            newVisit.mood = selectedMood
            newVisit.transports = selectedTransports.map(\.rawValue)
            newVisit.tripName = tripName
            newVisit.companions = companions
            newVisit.location = location
            newVisit.locationLatitude = locationLatitude
            newVisit.locationLongitude = locationLongitude
            modelContext.insert(newVisit)
            visit = newVisit
        }

        // 削除処理: 識別子の種類で振り分け
        var legacyFilenamesToDeleteFromDisk: [String] = []
        for identifier in Set(removedFilenames) {
            if let uuid = UUID(uuidString: identifier),
               let photo = visit.photos?.first(where: { $0.id == uuid }) {
                modelContext.delete(photo)
            } else {
                // legacy filename: photoFilenames / photoThumbnails 配列を同インデックスで削除
                if let idx = visit.photoFilenames.firstIndex(of: identifier) {
                    visit.photoFilenames.remove(at: idx)
                    var thumbs = visit.photoThumbnails
                    if idx < thumbs.count {
                        thumbs.remove(at: idx)
                        visit.photoThumbnails = thumbs
                    }
                }
                if visit.photoFilename == identifier {
                    visit.photoFilename = nil
                    visit.photoThumbnail = nil
                }
                legacyFilenamesToDeleteFromDisk.append(identifier)
            }
        }

        // 新規追加処理: photoFilenameMap[i] == nil のものを VisitPhoto として追加
        var addedPhotos: [VisitPhoto] = []
        for (i, image) in photoImages.enumerated() {
            if i < photoFilenameMap.count, photoFilenameMap[i] != nil {
                continue
            }
            if let photo = VisitPhotoStore.append(image: image, to: visit, in: modelContext) {
                addedPhotos.append(photo)
            }
        }

        do {
            try modelContext.save()
            for filename in legacyFilenamesToDeleteFromDisk {
                PhotoStorageManager.delete(filename: filename)
            }
            dismiss()
        } catch {
            // ロールバック: 追加した VisitPhoto を削除
            for photo in addedPhotos {
                modelContext.delete(photo)
            }
            try? modelContext.save()
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private func deleteVisit() {
        guard let visit = editingVisit else { return }
        let filenames = visit.allPhotoFilenames
        modelContext.delete(visit)
        do {
            try modelContext.save()
            for filename in filenames {
                PhotoStorageManager.delete(filename: filename)
            }
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }
}
