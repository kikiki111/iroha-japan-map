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
    @Environment(\.travelStyleCatalog) private var styleCatalog

    /// 選択中の都道府県 ID。配列順が訪問順になり、表示の「→」連結順に対応する。
    /// 居住 (`isResidenceMode`) では常に 1 要素。
    @State private var selectedPrefectureIDs: [Int] = []
    @State private var selectedKind: VisitKind = .travel
    @State private var visitDate = Date()
    @State private var endDate = Date()
    /// 旅行日の入力粒度。居住では使わない（`effectiveFormAccuracy` 参照）。
    @State private var dateAccuracy: DateAccuracy = .day
    /// 居住の終了日。`isOngoingResidence` が true のときは保存対象外。
    @State private var residenceEndDate = Date()
    @State private var isOngoingResidence = false
    /// 選択中の旅行スタイル ID。カタログで解決できない ID（他端末で作成し未同期など）でも
    /// 値は捨てずに保持する。同期完了後に自動で表示が戻る。
    @State private var selectedStyleID: String?
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
    /// 候補チップから非表示にした同行者名 (記録側の companions には影響しない)
    @State private var hiddenCompanions: Set<String> = CompanionSuggestionStore.hidden()
    @State private var location = ""
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var showDeleteConfirmation = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var isSaving = false
    @State private var isSelectingFromSuggestion = false
    @State private var didPopulate = false
    @FocusState private var locationFieldFocused: Bool
    @StateObject private var locationCompleter = LocationSearchCompleter()

    @Query(sort: \Visit.startDate) private var allVisits: [Visit]
    @State private var expandedSection: FormSection?
    @State private var prefectureSearch = ""
    @State private var activeDateField: DateField = .start
    @State private var pickerRefreshId = 0
    @State private var skipNextEndDateChange = false

    private var isEditing: Bool { editingVisit != nil }
    private let maxPhotoCount = 10
    /// 1 記録あたりの都道府県上限。行ヘッダのサマリと CloudKit レコードサイズを
    /// 現実的な範囲に保つための上限。
    private let maxPrefectureCount = 10
    /// 行ヘッダのサマリで連結表示する県数。超過分は「ほか N 県」に畳む。
    private let prefectureSummaryLimit = 2
    /// 年ホイールの下限。旅行記録として現実的な範囲に絞る。
    private let earliestSelectableYear = 1940
    private static let monthsInYear = Array(1...12)

    /// 年ホイールの選択肢（新しい年が先頭）。上限は今年。
    private var selectableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        guard currentYear >= earliestSelectableYear else { return [currentYear] }
        return Array((earliestSelectableYear...currentYear).reversed())
    }

    private enum FormSection: Hashable {
        case kind, prefecture, date, tag, location, transport, companion, mood, photo
    }

    private var isResidenceMode: Bool { selectedKind == .residence }

    /// 表示・保存に使う実効精度。
    /// 居住は `residencePeriodText` で既に年月粒度の表示を持つため、精度の概念を適用しない。
    private var effectiveFormAccuracy: DateAccuracy { isResidenceMode ? .day : dateAccuracy }

    private enum DateField {
        case start, end
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    kindRow
                    divider
                    prefectureRow
                    // 旅行スタイル (一人旅 / 家族旅行 …) は選択肢がすべて旅行前提のため
                    // 居住では出さない
                    if !isResidenceMode {
                        divider
                        tagRow
                    }
                    divider
                    if isResidenceMode {
                        residencePeriodRow
                    } else {
                        dateRow
                    }
                    divider
                    locationRow
                    divider
                    photoRow
                    // 移動手段・旅行名は旅行専用
                    if !isResidenceMode {
                        divider
                        transportRow
                    }
                    divider
                    companionRow
                    // ムードは「その時の気分」の単発スタンプで、
                    // 数年間の暮らしを 1 つで表すのは無理があるため居住では出さない
                    if !isResidenceMode {
                        divider
                        moodRow
                        divider
                        tripNameRow
                    }
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
            .navigationTitle(isResidenceMode ? "住んだ記録" : "旅の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("保存") { save() }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.irohaFujiDk)
                            .disabled(selectedPrefectureIDs.isEmpty)
                    }
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
            .overlay {
                if isSaving { savingOverlay }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.irohaWashi)
    }

    @ViewBuilder
    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("保存中…")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    // MARK: - Rows

    private var kindRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: selectedKind.iconName,
                label: "種別",
                value: selectedKind.displayName,
                valueColor: selectedKind.foregroundColor,
                section: .kind
            )

            if expandedSection == .kind {
                kindPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var kindPickerContent: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(VisitKind.allCases, id: \.rawValue) { kind in
                let isSelected = selectedKind == kind
                Button {
                    guard selectedKind != kind else { return }
                    selectedKind = kind
                    syncFieldsForKindChange(to: kind)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        expandedSection = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: kind.iconName)
                            .font(.system(size: 13))
                        Text(kind.displayName)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundColor(isSelected ? kind.foregroundColor : .irohaSumi3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? kind.backgroundColor : Color.irohaWashi2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? kind.foregroundColor.opacity(0.3) : Color.irohaWashi3, lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    /// 種別切替時に、もう一方のモードで不整合になる state を揃える。
    private func syncFieldsForKindChange(to kind: VisitKind) {
        switch kind {
        case .residence:
            // 居住は residencePeriodText で既に年月粒度の表示を持つため、精度の概念を持たない。
            // 曖昧精度のまま切り替えると「住みはじめた日」だけが代表日 (月末 / 12/31) に
            // 丸まり、residenceEndDate と粒度が食い違って期間表示が壊れる。
            dateAccuracy = .day
            // 旅行の帰着日を居住終了日の初期値として引き継ぐ
            if residenceEndDate < visitDate { residenceEndDate = max(endDate, visitDate) }
            // 居住は 1 県のみ。旅行で複数県を選んだ後に切り替えたら先頭県だけ残す
            if selectedPrefectureIDs.count > 1 {
                selectedPrefectureIDs = Array(selectedPrefectureIDs.prefix(1))
            }
        case .travel:
            // 居住から戻したときに endDate < visitDate の不正状態を作らない
            if endDate < visitDate {
                skipNextEndDateChange = true
                endDate = visitDate
            }
        }
    }

    private var residencePeriodRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "calendar",
                label: "期間",
                value: formattedResidenceSummary,
                section: .date
            )

            if expandedSection == .date {
                residencePeriodContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onChange(of: expandedSection) { _, newSection in
            if newSection == .date { activeDateField = .start }
        }
    }

    private var residencePeriodContent: some View {
        VStack(spacing: 8) {
            dateFieldRow(field: .start, label: "住みはじめた日", date: visitDate)
            if activeDateField == .start {
                DatePicker(
                    "住みはじめた日",
                    selection: $visitDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.irohaSumikaDk)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .labelsHidden()
                .id(pickerRefreshId)
                .onChange(of: visitDate) { oldDate, newDate in
                    if residenceEndDate < newDate { residenceEndDate = newDate }
                    if isUserDayTap(from: oldDate, to: newDate), !isOngoingResidence {
                        activeDateField = .end
                    }
                }

                pickerDoneLink
            }

            Toggle(isOn: $isOngoingResidence) {
                Text("現在も住んでいる")
                    .font(.system(size: 15))
                    .foregroundColor(.irohaSumi2)
            }
            .tint(.irohaSumikaDk)
            .padding(.vertical, 4)
            .onChange(of: isOngoingResidence) { _, isOngoing in
                if isOngoing, activeDateField == .end {
                    activeDateField = .start
                }
            }

            if !isOngoingResidence {
                dateFieldRow(field: .end, label: "引っ越した日", date: residenceEndDate)
                if activeDateField == .end {
                    DatePicker(
                        "引っ越した日",
                        selection: $residenceEndDate,
                        in: visitDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(.irohaSumikaDk)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .labelsHidden()
                    .id(pickerRefreshId)
                    .onChange(of: residenceEndDate) { oldDate, newDate in
                        if isUserDayTap(from: oldDate, to: newDate) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedSection = nil
                            }
                        }
                    }

                    pickerDoneLink
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var formattedResidenceSummary: String {
        let fmt = { (d: Date) in
            d.formatted(.dateTime.year().month().locale(Locale(identifier: "ja_JP")))
        }
        if isOngoingResidence {
            return "\(fmt(visitDate)) 〜 現在"
        }
        return "\(fmt(visitDate)) 〜 \(fmt(residenceEndDate))"
    }

    private var prefectureRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "mappin.circle",
                label: "都道府県",
                value: prefectureSummary,
                valueColor: selectedPrefectureIDs.isEmpty ? .irohaSumi3 : .irohaSumi,
                lineLimit: 1,
                // 県詳細シート経由でもロックしない (初期選択されるが他県を追加できる)
                section: .prefecture
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
            // カレンダー (年月日) 専用の初期位置合わせ。曖昧精度のホイールは
            // 選択中の年月をそのまま表示するので揃え直す必要がなく、
            // 揃えると入力済みの帰着日が開始日に巻き戻ってしまう。
            guard dateAccuracy == .day else { return }
            // 帰着日カレンダーが開始日の年月で開くように、年月が違っていたら開始日に揃える
            let calendar = Calendar.current
            let visitYM = calendar.dateComponents([.year, .month], from: visitDate)
            let endYM = calendar.dateComponents([.year, .month], from: endDate)
            if visitYM.year != endYM.year || visitYM.month != endYM.month {
                skipNextEndDateChange = true
                endDate = visitDate
            }
        }
        // 帰着日 picker が描画されているか否かに関わらず endDate 変更を捕捉するため、親 View レベルに配置。
        // 帰着日 picker 内に書くと、開始日操作中の endDate 自動調整時に発火せず、フラグが残留してしまう。
        .onChange(of: endDate) { oldDate, newDate in
            // 自動調整による変更（フラグ立ち）はスキップ。
            if skipNextEndDateChange {
                skipNextEndDateChange = false
                return
            }
            // 帰着日 picker 操作中のユーザー日タップで旅行日セクションを閉じる。
            // ホイール式年月ピッカーで日が自動調整されたケースのみ除外する。
            // 曖昧精度では日成分が常に月末に張り付き isUserDayTap が誤発火するため、
            // セクションを閉じる操作は「完了」ボタン (pickerDoneLink(for:)) に任せる。
            guard dateAccuracy == .day, activeDateField == .end else { return }
            if isUserDayTap(from: oldDate, to: newDate) {
                expandedSection = nil
            }
        }
    }

    /// 選択中スタイルの実体。ID が解決できない場合は nil（表示は「未選択」）。
    private var selectedStyle: TravelStyle? { styleCatalog.style(for: selectedStyleID) }

    private var tagRow: some View {
        VStack(spacing: 0) {
            rowHeader(
                icon: "tag",
                label: "旅行スタイル",
                value: selectedStyle?.name ?? "未選択",
                valueColor: selectedStyle?.foregroundColor ?? .irohaSumi3,
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
            TextField(isResidenceMode ? "住んでいた場所（例：松山市）" : "場所名（例：道後温泉）", text: $location)
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

                Text(isResidenceMode ? "同居した人" : "同行者")
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
        let available = all.subtracting(current).subtracting(hiddenCompanions)
        if companionInput.isEmpty { return Array(available).sorted() }
        return available.filter { $0.localizedCaseInsensitiveContains(companionInput) }.sorted()
    }

    private func addCompanion() {
        let name = companionInput.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !companions.contains(name) else { return }
        companions.append(name)
        companionInput = ""
        // 非表示にした名前を手入力で入れ直したら、候補として復活させる (復元手段の確保)
        if hiddenCompanions.contains(name) {
            CompanionSuggestionStore.unhide(name)
            hiddenCompanions.remove(name)
        }
    }

    /// 候補チップから名前を非表示にする (過去の記録は変更しない)
    private func hideCompanionSuggestion(_ name: String) {
        CompanionSuggestionStore.hide(name)
        hiddenCompanions.insert(name)
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
                    Text("候補（長押しで削除）")
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
                            .contextMenu {
                                Button(role: .destructive) {
                                    hideCompanionSuggestion(name)
                                } label: {
                                    Label("候補から削除", systemImage: "trash")
                                }
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
                    Text(isResidenceMode ? "暮らしの思い出を残しておこう…" : "旅の思い出を残しておこう…")
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

            // 選択済みチップ (訪問順)。47 チップの地方グリッドより上に置くことで、
            // スクロールせずに選んだ順序と件数を確認できるようにする。
            // 居住は 1 県固定なのでチップ一覧を出さない。
            if !isResidenceMode, !selectedPrefectureIDs.isEmpty {
                selectedPrefectureChips
            }

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
                                let isSelected = selectedPrefectureIDs.contains(pref.id)
                                let isFull = selectedPrefectureIDs.count >= maxPrefectureCount
                                Button {
                                    togglePrefecture(pref)
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
                                // 上限到達後は未選択の県を押せなくする (居住は常に置き換えなので対象外)
                                .disabled(!isResidenceMode && !isSelected && isFull)
                                .opacity(!isResidenceMode && !isSelected && isFull ? 0.4 : 1)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    /// 選択済み都道府県のチップ列 (訪問順)。× で個別に外せる。
    private var selectedPrefectureChips: some View {
        VStack(spacing: 4) {
            FlowLayout(spacing: 6) {
                ForEach(selectedPrefectureIDs, id: \.self) { id in
                    let name = Prefecture.by(id: id)?.name ?? ""
                    HStack(spacing: 4) {
                        Text(name)
                            .font(.system(size: 13))
                        Button {
                            selectedPrefectureIDs.removeAll { $0 == id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.irohaSumi3)
                        }
                        .accessibilityLabel("\(name)を選択から外す")
                    }
                    .foregroundColor(.irohaSumi)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.irohaWashi2)
                    .clipShape(Capsule())
                }
            }

            Text(verbatim: "\(selectedPrefectureIDs.count) / \(maxPrefectureCount)")
                .font(.system(size: 11))
                .foregroundColor(.irohaSumi3)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    /// 都道府県チップのタップ処理。
    /// 旅行は複数選択のトグル (移動手段ピッカーと同じ挙動、セクションは閉じない)。
    /// 居住は 1 県固定なので従来どおり単一選択で、選んだらセクションを閉じる。
    private func togglePrefecture(_ pref: Prefecture) {
        prefectureSearch = ""

        guard !isResidenceMode else {
            selectedPrefectureIDs = [pref.id]
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedSection = nil
            }
            return
        }

        if let index = selectedPrefectureIDs.firstIndex(of: pref.id) {
            selectedPrefectureIDs.remove(at: index)
        } else {
            guard selectedPrefectureIDs.count < maxPrefectureCount else { return }
            // 末尾に足すことで「選んだ順 = 訪問順」を保つ
            selectedPrefectureIDs.append(pref.id)
        }
    }

    private var datePickerContent: some View {
        VStack(spacing: 8) {
            accuracySegment

            dateFieldRow(field: .start, label: "開始日", date: visitDate)
            if activeDateField == .start {
                datePicker(for: .start)
                pickerDoneLink(for: .start)
            }

            dateFieldRow(field: .end, label: "帰着日", date: endDate)
            if activeDateField == .end {
                datePicker(for: .end)
                pickerDoneLink(for: .end)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var pickerDoneLink: some View {
        HStack {
            Spacer()
            Button {
                // 完了ボタンは「ホイール式年月ピッカーを閉じてグリッドに戻す」リフレッシュのみ。
                // 開始日 → 帰着日 picker への遷移、および 帰着日 → セクション閉じる動作は、
                // いずれも日付グリッドの日タップで自動的に行われる。
                pickerRefreshId += 1
            } label: {
                doneLinkLabel
            }
        }
    }

    /// 旅行日ピッカーの「完了」。精度によって役割が変わる。
    ///
    /// - 年月日: 従来どおりグリッドへ戻すリフレッシュのみ（遷移は日タップが担う）
    /// - 年月 / 年: ホイールには「日タップ」がないので、完了ボタンが遷移を担う
    private func pickerDoneLink(for field: DateField) -> some View {
        HStack {
            Spacer()
            Button {
                guard dateAccuracy != .day else {
                    pickerRefreshId += 1
                    return
                }
                if field == .start {
                    activeDateField = .end
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) { expandedSection = nil }
                }
            } label: {
                doneLinkLabel
            }
        }
    }

    private var doneLinkLabel: some View {
        Text("完了")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.irohaFuji)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
    }

    /// 旅行日の入力粒度セグメント。居住では表示しない（`datePickerContent` 内でのみ使う）。
    private var accuracySegment: some View {
        HStack(spacing: 6) {
            ForEach(DateAccuracy.allCases, id: \.rawValue) { accuracy in
                let isSelected = dateAccuracy == accuracy
                Button {
                    changeAccuracy(to: accuracy)
                } label: {
                    Text(accuracy.displayName)
                        .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .white : .irohaSumi2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.irohaFujiDk : Color.irohaWashi2)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(isSelected ? Color.irohaFujiDk : Color.irohaWashi3,
                                             lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }

    /// 精度に応じた日付ピッカー。
    @ViewBuilder
    private func datePicker(for field: DateField) -> some View {
        switch dateAccuracy {
        case .day:   graphicalDatePicker(for: field)
        case .month: yearMonthWheel(for: field)
        case .year:  yearWheel(for: field)
        }
    }

    /// 年月日モードのカレンダー。精度導入前の実装をそのまま使う。
    @ViewBuilder
    private func graphicalDatePicker(for field: DateField) -> some View {
        switch field {
        case .start:
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
                    skipNextEndDateChange = true
                    endDate = calendar.date(byAdding: .day, value: max(duration, 0), to: newDate) ?? newDate
                }
                // ユーザーの日タップ（同月内 or 横スライド/月送り後）で帰着日へ遷移。
                // ホイール式年月ピッカーで日が自動調整されたケース（5/31→6/30 等）のみ除外する。
                if isUserDayTap(from: oldDate, to: newDate) {
                    activeDateField = .end
                }
            }
        case .end:
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
        }
    }

    /// 年月モードのホイール。iOS 標準の `DatePicker` に「年月のみ」スタイルがないため自前で組む。
    private func yearMonthWheel(for field: DateField) -> some View {
        HStack(spacing: 0) {
            Picker("年", selection: yearBinding(for: field)) {
                ForEach(selectableYears, id: \.self) { year in
                    Text(verbatim: "\(year)年").tag(year)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("月", selection: monthBinding(for: field)) {
                ForEach(Self.monthsInYear, id: \.self) { month in
                    Text(verbatim: "\(month)月").tag(month)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 150)
        .id(pickerRefreshId)
    }

    /// 年モードのホイール。
    private func yearWheel(for field: DateField) -> some View {
        Picker("年", selection: yearBinding(for: field)) {
            ForEach(selectableYears, id: \.self) { year in
                Text(verbatim: "\(year)年").tag(year)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 150)
        .id(pickerRefreshId)
    }

    // MARK: - 曖昧精度ピッカーの Binding
    //
    // `visitDate` / `endDate` (Date) を単一の真実とし、ホイールは Binding<Int> 越しに
    // 読み書きする。State を年・月に分割して二重管理しない。

    private func date(for field: DateField) -> Date {
        field == .start ? visitDate : endDate
    }

    private func yearBinding(for field: DateField) -> Binding<Int> {
        Binding(
            get: { Calendar.current.component(.year, from: date(for: field)) },
            set: { setDateComponent(.year, to: $0, for: field) }
        )
    }

    private func monthBinding(for field: DateField) -> Binding<Int> {
        Binding(
            get: { Calendar.current.component(.month, from: date(for: field)) },
            set: { setDateComponent(.month, to: $0, for: field) }
        )
    }

    /// 年 or 月だけを差し替え、精度に応じた代表日へ丸めて格納する。
    private func setDateComponent(_ component: Calendar.Component, to value: Int, for field: DateField) {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: date(for: field))
        switch component {
        case .year:  comps.year = value
        case .month: comps.month = value
        default:     return
        }
        // 月初で組み立ててから正規化する。日を保ったまま月を差し替えると、
        // その月に存在しない日 (2月31日 など) が翌月に繰り上がってしまうため
        // (DateComponents は nil を返さず 2015/2/31 → 2015-03-03 を返す)。
        comps.day = 1
        guard let rebuilt = calendar.date(from: comps) else { return }
        assign(dateAccuracy.normalized(rebuilt), to: field)
    }

    /// 正規化済みの日付を State に反映する。開始日 ≤ 帰着日 の関係をここで担保する。
    private func assign(_ newDate: Date, to field: DateField) {
        switch field {
        case .start:
            visitDate = newDate
            if newDate > endDate {
                skipNextEndDateChange = true
                endDate = newDate
            }
        case .end:
            // 曖昧精度では帰着日ピッカーに `in: visitDate...` の制約がない
            // (ホイールは範囲指定できない) ため、ここでクランプする。
            skipNextEndDateChange = true
            endDate = max(newDate, visitDate)
        }
    }

    /// 精度を切り替え、既存の日付を新しい精度の代表日へ丸める。
    ///
    /// 例: `.day` 2015/5/3 → `.month` → 2015/5/31 → `.year` → 2015/12/31
    /// 粗い精度から戻しても元の日は復元しない (2015/12/31 のまま)。
    private func changeAccuracy(to newAccuracy: DateAccuracy) {
        guard newAccuracy != dateAccuracy else { return }
        dateAccuracy = newAccuracy

        // 年ホイールの選択肢外の年 (カレンダーは範囲無制限なので入り得る) を先に丸める
        let clampedStart = clampToSelectableYear(visitDate)
        let clampedEnd   = clampToSelectableYear(endDate)

        let normalizedStart = newAccuracy.normalized(clampedStart)
        let normalizedEnd   = max(newAccuracy.normalized(clampedEnd), normalizedStart)

        visitDate = normalizedStart
        skipNextEndDateChange = true
        endDate = normalizedEnd

        activeDateField = .start
        pickerRefreshId += 1
    }

    /// 年を `selectableYears` の範囲に収める。範囲外なら端の年の同月同日に寄せる。
    private func clampToSelectableYear(_ date: Date) -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        guard let lowest = selectableYears.last, let highest = selectableYears.first,
              year < lowest || year > highest else {
            return date
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.year = min(max(year, lowest), highest)
        return calendar.date(from: comps) ?? date
    }

    private func dateFieldRow(field: DateField, label: String, date: Date) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.irohaSumi2)
            Spacer()
            Text(VisitDateFormat.text(date, accuracy: effectiveFormAccuracy))
                .font(.system(size: 15))
                .foregroundColor(activeDateField == field ? .irohaFuji : .irohaSumi)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { activeDateField = field }
    }

    // DatePicker の selection 変更が「ユーザーの日タップ」によるものか判定する。
    // 同月内の日変化、および横スライド/月送り後の日タップを「日タップ」とみなす。
    // ホイール式年月ピッカーで新月にその日が存在せず最終日に切り詰められたケース
    // (例: 5/31 → 6/30) のみ除外。
    private func isUserDayTap(from oldDate: Date, to newDate: Date) -> Bool {
        let calendar = Calendar.current
        let oldComp = calendar.dateComponents([.year, .month, .day], from: oldDate)
        let newComp = calendar.dateComponents([.year, .month, .day], from: newDate)
        guard let oldDay = oldComp.day, let newDay = newComp.day, oldDay != newDay else {
            return false
        }
        if oldComp.year == newComp.year && oldComp.month == newComp.month {
            return true
        }
        let newMonthLastDay = (calendar.range(of: .day, in: .month, for: newDate)?.upperBound ?? 32) - 1
        let isWheelAutoAdjustment = (newDay == newMonthLastDay) && (oldDay > newMonthLastDay)
        return !isWheelAutoAdjustment
    }

    private var tagPickerContent: some View {
        // 編集中の記録が非表示にされたプリセットを使っている場合、そのスタイルだけ
        // 選択肢に残す。保存し直しただけでスタイルが外れるのを防ぐ。
        let styles = styleCatalog.selectableIncluding(selectedStyle)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(styles) { style in
                let isSelected = selectedStyleID == style.id
                Button {
                    // 再タップで選択解除
                    selectedStyleID = isSelected ? nil : style.id
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: style.iconName)
                            .font(.system(size: 13))
                        Text(style.name)
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .foregroundColor(isSelected ? style.foregroundColor : .irohaSumi3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? style.backgroundColor : Color.irohaWashi2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? style.foregroundColor.opacity(0.3) : Color.irohaWashi3, lineWidth: 0.5)
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

    /// - Parameter lineLimit: 値テキストの行数上限。既定 (nil) は無制限。
    ///   長い値でも折り返して全文を見せたい行 (日付・場所) はそのまま、
    ///   1 行に収めたい行 (都道府県) だけ 1 を渡す。
    private func rowHeader(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .irohaSumi,
        lineLimit: Int? = nil,
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
                .lineLimit(lineLimit)
                .truncationMode(.tail)

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
        // 同日 (精度上で同一) なら単一表示になる出し分けは VisitDateFormat が担当する
        VisitDateFormat.rangeText(from: visitDate, to: endDate,
                                  accuracy: effectiveFormAccuracy, separator: "→")
    }

    /// 行ヘッダ用のサマリ。幅が限られるため `prefectureSummaryLimit` 県までを連結し、
    /// 超過分は「ほか N 県」に畳む。全県の並びは展開したピッカーのチップで確認できる。
    private var prefectureSummary: String {
        guard !selectedPrefectureIDs.isEmpty else { return "選択してください" }
        let names = selectedPrefectureIDs.compactMap { Prefecture.by(id: $0)?.name }
        guard names.count > prefectureSummaryLimit else {
            return names.joined(separator: Visit.prefectureSeparator)
        }
        return names.prefix(prefectureSummaryLimit).joined(separator: Visit.prefectureSeparator)
            + " ほか\(names.count - prefectureSummaryLimit)県"
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
            selectedPrefectureIDs = visit.effectivePrefectureIDs
            selectedKind = visit.effectiveKind
            visitDate = visit.startDate
            endDate = visit.effectiveEndDate
            dateAccuracy = visit.effectiveDateAccuracy
            isOngoingResidence = visit.isResidenceOngoing
            // 終了日なし (継続中 or 未設定) の場合は開始日を初期値にする
            residenceEndDate = visit.residenceEndDate ?? visit.startDate
            selectedStyleID = visit.effectiveStyleID
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
            // 県詳細シート由来。初期値として入れるだけでロックはしない
            selectedPrefectureIDs = [pref.id]
        } else {
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
        guard !isSaving else { return }

        // 日付精度に応じた代表日へ正規化してから保存する。丸めはここ 1 箇所に集約し、
        // 読み出し側は「startDate は既に代表日」と信頼する。
        let accuracy = effectiveFormAccuracy
        let normalizedStartDate = accuracy.normalized(visitDate)
        // 旅行: endDate は「同日なら nil (= 日帰り)」。居住では使わない。
        // 居住: 期間は residenceEndDate / isResidenceOngoing 側に持たせる。
        let computedEndDate: Date? = {
            guard !isResidenceMode else { return nil }
            let normalizedEndDate = accuracy.normalized(endDate)
            // 精度上で同一なら畳む (年月精度なら「同じ月」で日帰り扱い)
            return accuracy.isSame(normalizedStartDate, normalizedEndDate) ? nil : normalizedEndDate
        }()
        let computedResidenceEndDate: Date? = {
            guard isResidenceMode, !isOngoingResidence else { return nil }
            return residenceEndDate
        }()
        let computedIsOngoing = isResidenceMode && isOngoingResidence
        // 旅行スタイル・移動手段・ムード・旅行名は旅行専用。
        // 居住では入力欄を出さないので保存もしない (種別を切り替えたときに
        // 見えていない値が残らないよう、明示的にクリアする)。
        let computedTag: String? = isResidenceMode ? nil : selectedStyleID
        let computedMood: VisitMood = isResidenceMode ? .none : selectedMood
        let computedTransports = isResidenceMode ? [] : selectedTransports.map(\.rawValue)
        let computedTripName = isResidenceMode ? "" : tripName
        // 日付精度も旅行専用 (居住は年月粒度の専用表示を持つ)
        let computedDateAccuracy: DateAccuracy = isResidenceMode ? .day : dateAccuracy
        // 複数県は旅行専用。居住は先頭 1 県に切り詰める (UI 側でも単一選択にしているが、
        // 種別を切り替えた直後の取りこぼしを防ぐ保険)。
        let computedPrefectureIDs = isResidenceMode
            ? Array(selectedPrefectureIDs.prefix(1))
            : selectedPrefectureIDs
        // 旧 prefectureID / prefectureName には先頭県をミラーする
        let primaryPrefectureID = computedPrefectureIDs.first ?? 0
        let primaryPrefectureName = Prefecture.by(id: primaryPrefectureID)?.name ?? ""

        // メタデータ更新 (Visit を確保)
        let visit: Visit
        if let existing = editingVisit {
            visit = existing
            // kind を先に確定させる (setPrefectureIDs が居住なら 1 県に切り詰めるため)
            visit.kind = selectedKind
            visit.setPrefectureIDs(computedPrefectureIDs)
            visit.startDate = normalizedStartDate
            visit.endDate = computedEndDate
            visit.dateAccuracy = computedDateAccuracy
            visit.residenceEndDate = computedResidenceEndDate
            visit.isResidenceOngoing = computedIsOngoing
            visit.setStyleID(computedTag)
            visit.mood = computedMood
            visit.transports = computedTransports
            visit.note = memo
            visit.tripName = computedTripName
            visit.companions = companions
            visit.location = location
            visit.locationLatitude = locationLatitude
            visit.locationLongitude = locationLongitude
        } else {
            let newVisit = Visit(
                prefectureName: primaryPrefectureName,
                prefectureID: primaryPrefectureID,
                prefectureIDs: computedPrefectureIDs,
                startDate: normalizedStartDate,
                endDate: computedEndDate,
                note: memo,
                styleID: computedTag,
                kind: selectedKind,
                residenceEndDate: computedResidenceEndDate,
                isResidenceOngoing: computedIsOngoing,
                dateAccuracy: computedDateAccuracy
            )
            newVisit.mood = computedMood
            newVisit.transports = computedTransports
            newVisit.tripName = computedTripName
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

        // 新規追加対象を抽出 (photoFilenameMap[i] == nil のもの)
        var newImages: [(index: Int, image: UIImage)] = []
        for (i, image) in photoImages.enumerated() {
            if i < photoFilenameMap.count, photoFilenameMap[i] != nil {
                continue
            }
            newImages.append((i, image))
        }

        isSaving = true

        // background で並列圧縮 → MainActor で順序通り insert + save
        Task {
            let payloads = await Self.compressInParallel(newImages)

            await MainActor.run {
                var addedPhotos: [VisitPhoto] = []
                for (_, payload) in payloads {
                    let inserted = VisitPhotoStore.insert(payload: payload, into: visit, in: modelContext)
                    addedPhotos.append(inserted)
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
                    isSaving = false
                }
            }
        }
    }

    /// 写真群を並列で圧縮し、入力 index 昇順で結果を返す。
    /// 圧縮失敗 (nil) は結果から除外。並列度は min(4, processorCount) で頭打ち。
    private static func compressInParallel(
        _ images: [(index: Int, image: UIImage)]
    ) async -> [(index: Int, payload: VisitPhotoStore.CompressedPhotoPayload)] {
        guard !images.isEmpty else { return [] }
        let maxConcurrency = min(4, max(2, ProcessInfo.processInfo.activeProcessorCount))

        return await withTaskGroup(of: (Int, VisitPhotoStore.CompressedPhotoPayload?).self) { group in
            var iterator = images.makeIterator()
            // 初期投入: 並列度ぶんだけ先行投入
            for _ in 0..<maxConcurrency {
                guard let next = iterator.next() else { break }
                let capturedIndex = next.index
                let capturedImage = next.image
                group.addTask(priority: .userInitiated) {
                    (capturedIndex, VisitPhotoStore.makePayload(from: capturedImage))
                }
            }

            var results: [(Int, VisitPhotoStore.CompressedPhotoPayload)] = []
            while let (index, payload) = await group.next() {
                if let payload {
                    results.append((index, payload))
                }
                // 完了ごとに次の 1 件を投入 (常に maxConcurrency 並列を維持)
                if let next = iterator.next() {
                    let capturedIndex = next.index
                    let capturedImage = next.image
                    group.addTask(priority: .userInitiated) {
                        (capturedIndex, VisitPhotoStore.makePayload(from: capturedImage))
                    }
                }
            }
            results.sort { $0.0 < $1.0 }
            return results.map { (index: $0.0, payload: $0.1) }
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
