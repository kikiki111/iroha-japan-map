//
//  TimelineView.swift
//  Iroha
//
//  旅の記録タブ（タイムライン）

import SwiftUI
import SwiftData

// MARK: - TimelineView

struct TimelineView: View {
    var mapViewModel: MapViewModel

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Visit.startDate, order: .reverse) private var visits: [Visit]
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var selectedYear: Int = 0
    @State private var showAddVisit = false
    @State private var editingVisit: Visit?

    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(visits.map { calendar.component(.year, from: $0.startDate) })
        return years.sorted(by: >)
    }

    private var currentYear: Int {
        selectedYear > 0 ? selectedYear : (availableYears.first ?? Calendar.current.component(.year, from: Date()))
    }

    private var filteredVisits: [Visit] {
        let calendar = Calendar.current
        return visits.filter { calendar.component(.year, from: $0.startDate) == currentYear }
    }

    private var wantedPrefectures: [Prefecture] {
        prefectures.filter { ($0.isWanted || $0.isBookmarked) && !$0.isVisited }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visits.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("旅の記録")
                        .font(.system(size: 20, weight: .light, design: .serif))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddVisit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15))
                            .foregroundColor(.irohaSumi2)
                    }
                }
            }
            .sheet(isPresented: $showAddVisit) {
                AddVisitSheetView(prefectures: prefectures)
            }
            .sheet(item: $editingVisit) { visit in
                EditVisitSheetView(visit: visit, prefectures: prefectures)
            }
        }
    }

    // MARK: - Timeline content

    private var timelineContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                yearSwitcher
                yearHeader
                tripGroupCards
                monthSections
                wantedSection
            }
        }
    }

    // MARK: - Year switcher

    private var yearSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(availableYears, id: \.self) { year in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedYear = year
                        }
                    } label: {
                        Text(verbatim: "\(year)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(currentYear == year ? .white : .irohaSumi2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(currentYear == year ? Color.irohaFujiDk : Color.irohaWashi2)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
    }

    // MARK: - Year header

    private var yearHeader: some View {
        let yearVisits = filteredVisits
        let prefCount = Set(yearVisits.map(\.prefectureName)).count
        let visitCount = yearVisits.count

        return HStack(alignment: .bottom) {
            NurikakeText(text: "\(currentYear)", fontSize: 36)

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 3) {
                    Text(verbatim: "\(prefCount)県")
                        .font(.system(size: 14, weight: .bold))
                    Text("\u{00B7}")
                        .foregroundColor(.irohaSumi3)
                    Text(verbatim: "\(visitCount)回")
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi3)
                }

                Button {
                    shareYearRecap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("シェア")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.irohaFujiDk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.irohaFujiLt.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.irohaFujiLt, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Trip group cards

    private var tripGroupCards: some View {
        let trips = TripDetector.detect(from: filteredVisits).filter { $0.visits.count >= 2 }

        return ForEach(trips) { trip in
            tripCard(trip: trip)
        }
    }

    private func tripCard(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Text("\u{1F4CD}")
                    .font(.system(size: 14))
                let nights = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
                Text("\(nights > 0 ? "\(nights)泊\(nights + 1)日" : "日帰り")")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(.irohaFujiDk)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.irohaFujiDk)

            // Route chips
            HStack(spacing: 4) {
                ForEach(Array(trip.prefectureNames.enumerated()), id: \.offset) { i, name in
                    Text(name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.irohaFujiDk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.irohaFujiLt.opacity(0.35))
                        .clipShape(Capsule())

                    if i < trip.prefectureNames.count - 1 {
                        Text("\u{2192}")
                            .font(.system(size: 12))
                            .foregroundColor(.irohaSumi3)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.irohaFujiLt.opacity(0.22), Color.irohaFujiLt.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.irohaFuji)
                    .frame(width: 3)
                Spacer()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }

    // MARK: - Month sections

    private var monthSections: some View {
        let calendar = Calendar.current
        var byMonth: [Int: [Visit]] = [:]
        for visit in filteredVisits {
            let month = calendar.component(.month, from: visit.startDate)
            byMonth[month, default: []].append(visit)
        }
        let sortedMonths = byMonth.keys.sorted(by: >)

        return ForEach(sortedMonths, id: \.self) { month in
            VStack(spacing: 0) {
                // Month divider
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.irohaWashi3)
                        .frame(height: 0.5)
                    Text("\(month)月")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.irohaSumi3)
                        .tracking(1.5)
                    Rectangle()
                        .fill(Color.irohaWashi3)
                        .frame(height: 0.5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5)

                // Visits
                ForEach((byMonth[month] ?? []).sorted(by: { $0.startDate > $1.startDate })) { visit in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.visitColor(
                                count: prefectures.first(where: { $0.name == visit.prefectureName })?.visitCount ?? 0
                            ))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(visit.prefectureName)
                                    .font(.system(size: 15, weight: .bold))
                                if visit.effectiveTag != .none {
                                    VisitTagBadge(tag: visit.effectiveTag)
                                }
                            }
                            if !visit.note.isEmpty {
                                Text(visit.note)
                                    .font(.system(size: 13))
                                    .foregroundColor(.irohaSumi2)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingVisit = visit
                    }
                }
            }
        }
    }

    // MARK: - Wanted section

    private var wantedSection: some View {
        Group {
            if !wantedPrefectures.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("\u{2661} 行きたい")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.irohaSumi2)
                            .tracking(1)
                        Spacer()
                    }

                    // Chips
                    FlowLayout(spacing: 5) {
                        ForEach(wantedPrefectures) { pref in
                            HStack(spacing: 4) {
                                Text("\u{2661}")
                                    .font(.system(size: 12))
                                    .foregroundColor(.irohaFuji)
                                Text(pref.name)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.irohaFuji, style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 10)
                .border(width: 0.5, edges: [.top], color: Color.irohaWashi3)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("訪問記録がありません", systemImage: "map")
        } description: {
            Text("＋ボタンから訪問した都道府県を追加しましょう。")
        }
    }

    // MARK: - Share

    private func shareYearRecap() {
        ShareManager.shareMap(prefectures: prefectures)
    }
}

// MARK: - FlowLayout

/// シンプルなフローレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxHeight = max(maxHeight, y + rowHeight)
        }

        return (CGSize(width: maxWidth, height: maxHeight), positions)
    }
}

// MARK: - AddVisitSheetView

struct AddVisitSheetView: View {
    let prefectures: [Prefecture]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPrefectureName = ""
    @State private var visitDate = Date()
    @State private var selectedTag: VisitTag = .none
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("都道府県") {
                    Picker("都道府県", selection: $selectedPrefectureName) {
                        ForEach(prefectures) { pref in
                            Text(pref.name).tag(pref.name)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section("訪問日") {
                    DatePicker("", selection: $visitDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .tint(.irohaFuji)
                }

                Section("訪問スタイル") {
                    HStack(spacing: 6) {
                        ForEach([VisitTag.dayTrip, .stay, .lived], id: \.rawValue) { tag in
                            Button {
                                selectedTag = selectedTag == tag ? .none : tag
                            } label: {
                                Text(tag.displayName)
                                    .font(.system(size: 14, weight: selectedTag == tag ? .bold : .medium))
                                    .foregroundColor(selectedTag == tag ? .irohaFujiDk : .irohaSumi3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedTag == tag
                                            ? Color.irohaFuji.opacity(0.12)
                                            : Color.irohaWashi2
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedTag == tag ? Color.irohaFuji : Color.irohaWashi3, lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }

                Section("メモ（任意）") {
                    TextField("旅の思い出を残しておこう…", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .onAppear {
                if selectedPrefectureName.isEmpty, let first = prefectures.first {
                    selectedPrefectureName = first.name
                }
            }
            .navigationTitle("訪問を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedPrefectureName.isEmpty)
                        .foregroundColor(.irohaFujiDk)
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private func save() {
        let visit = Visit(
            prefectureName: selectedPrefectureName,
            startDate: visitDate,
            note: memo,
            tag: selectedTag
        )
        visit.prefecture = prefectures.first { $0.name == selectedPrefectureName }
        modelContext.insert(visit)
        dismiss()
    }
}

// MARK: - EditVisitSheetView

struct EditVisitSheetView: View {
    @Bindable var visit: Visit
    let prefectures: [Prefecture]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPrefectureName = ""
    @State private var visitDate = Date()
    @State private var selectedTag: VisitTag = .none
    @State private var memo = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("都道府県") {
                    Picker("都道府県", selection: $selectedPrefectureName) {
                        ForEach(prefectures) { pref in
                            Text(pref.name).tag(pref.name)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("訪問日") {
                    DatePicker("", selection: $visitDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .tint(.irohaFuji)
                }

                Section("訪問スタイル") {
                    HStack(spacing: 6) {
                        ForEach([VisitTag.dayTrip, .stay, .lived], id: \.rawValue) { tag in
                            Button {
                                selectedTag = selectedTag == tag ? .none : tag
                            } label: {
                                Text(tag.displayName)
                                    .font(.system(size: 14, weight: selectedTag == tag ? .bold : .medium))
                                    .foregroundColor(selectedTag == tag ? .irohaFujiDk : .irohaSumi3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedTag == tag
                                            ? Color.irohaFuji.opacity(0.12)
                                            : Color.irohaWashi2
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedTag == tag ? Color.irohaFuji : Color.irohaWashi3, lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }

                Section("メモ（任意）") {
                    TextField("メモ", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("この記録を削除", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .onAppear {
                selectedPrefectureName = visit.prefectureName
                visitDate = visit.startDate
                selectedTag = visit.effectiveTag
                memo = visit.note
            }
            .navigationTitle("旅の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(selectedPrefectureName.isEmpty)
                        .foregroundColor(.irohaFujiDk)
                }
            }
            .confirmationDialog("この記録を削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    if let filename = visit.photoFilename {
                        PhotoStorageManager.delete(filename: filename)
                    }
                    modelContext.delete(visit)
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
    }

    private func save() {
        visit.prefectureName = selectedPrefectureName
        visit.startDate = visitDate
        visit.tag = selectedTag
        visit.note = memo
        visit.prefecture = prefectures.first { $0.name == selectedPrefectureName }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    TimelineView(mapViewModel: vm)
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
