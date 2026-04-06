//
//  TimelineView.swift
//  Iroha
//

import SwiftUI
import SwiftData

// MARK: - TimelineView

/// 訪問履歴を年月でグループ分けして表示するタイムラインビュー
struct TimelineView: View {
    var mapViewModel: MapViewModel

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Visit.startDate, order: .reverse) private var visits: [Visit]
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var isShowingAddVisit = false
    @State private var editingVisit: Visit?

    // MARK: - Prefecture lookup

    private func findPrefecture(byName name: String) -> Prefecture? {
        prefectures.first { $0.name == name }
    }

    // MARK: - Grouping

    private var visitsByYear: [YearGroup] {
        let calendar = Calendar.current
        var byYearMonth: [Int: [Int: [Visit]]] = [:]
        for visit in visits {
            let year  = calendar.component(.year,  from: visit.startDate)
            let month = calendar.component(.month, from: visit.startDate)
            byYearMonth[year, default: [:]][month, default: []].append(visit)
        }
        return byYearMonth.keys.sorted(by: >).map { year in
            let monthDict   = byYearMonth[year] ?? [:]
            let monthGroups = monthDict.keys.sorted(by: >).map { month in
                MonthGroup(
                    year: year,
                    month: month,
                    visits: (monthDict[month] ?? []).sorted { $0.startDate > $1.startDate }
                )
            }
            return YearGroup(year: year, monthGroups: monthGroups)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if visits.isEmpty {
                    emptyStateView
                } else {
                    visitList
                }
            }
            .navigationTitle("タイムライン")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddVisit = true
                    } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddVisit) {
                AddVisitView()
            }
            .sheet(item: $editingVisit) { visit in
                EditVisitView(visit: visit)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Subviews

    private var visitList: some View {
        List {
            ForEach(visitsByYear) { yearGroup in
                Section {
                    ForEach(yearGroup.monthGroups) { monthGroup in
                        Text(monthGroup.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color(.systemGroupedBackground))

                        ForEach(monthGroup.visits) { visit in
                            VisitRow(visit: visit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingVisit = visit
                                }
                        }
                        .onDelete { offsets in deleteVisits(offsets, from: monthGroup.visits) }
                    }
                } header: {
                    YearHeaderView(
                        year: yearGroup.year,
                        summary: yearSummary(for: yearGroup.year)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("訪問記録がありません", systemImage: "map")
        } description: {
            Text("＋ボタンから訪問した都道府県を追加しましょう。")
        }
    }

    // MARK: - Helpers

    private func yearSummary(for year: Int) -> YearSummary {
        let calendar    = Calendar.current
        let yearVisits  = visits.filter { calendar.component(.year, from: $0.startDate) == year }
        let uniqueNames = Set(yearVisits.map(\.prefectureName))
        let farthest    = uniqueNames
            .compactMap { findPrefecture(byName: $0) }
            .max(by: { $0.distanceFromTokyo < $1.distanceFromTokyo })
        return YearSummary(
            visitCount: yearVisits.count,
            prefectureCount: uniqueNames.count,
            farthestPrefectureName: farthest?.name
        )
    }

    private func deleteVisits(_ offsets: IndexSet, from source: [Visit]) {
        for index in offsets {
            modelContext.delete(source[index])
        }
    }
}

// MARK: - Supporting types

private struct YearGroup: Identifiable {
    let year: Int
    let monthGroups: [MonthGroup]
    var id: Int { year }
}

private struct MonthGroup: Identifiable {
    let year: Int
    let month: Int
    let visits: [Visit]
    var id: String { "\(year)-\(month)" }

    var label: String {
        "\(month)月"
    }
}

struct YearSummary {
    let visitCount: Int
    let prefectureCount: Int
    let farthestPrefectureName: String?
}

// MARK: - Date formatting

private let slashDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M/d"
    return f
}()

// MARK: - TravelDatePicker

/// カレンダーを2度タップして出発日・帰着日を設定するピッカー
private struct TravelDatePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var selectingEndDate = false

    private var currentDate: Binding<Date> {
        Binding(
            get: { selectingEndDate ? endDate : startDate },
            set: { newDate in
                if selectingEndDate {
                    endDate = max(newDate, startDate)
                } else {
                    startDate = newDate
                    if endDate < newDate { endDate = newDate }
                    selectingEndDate = true
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                dateChip(title: "出発日", date: startDate, isActive: !selectingEndDate)
                    .onTapGesture { selectingEndDate = false }
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                dateChip(title: "帰着日", date: endDate, isActive: selectingEndDate)
                    .onTapGesture { selectingEndDate = true }
            }

            DatePicker("", selection: currentDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .tint(Color(hex: "#7F77DD"))
        }
    }

    private func dateChip(title: String, date: Date, isActive: Bool) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(slashDateFormatter.string(from: date))
                .font(.subheadline)
                .fontWeight(isActive ? .bold : .regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isActive ? Color(hex: "#7F77DD").opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - YearHeaderView

struct YearHeaderView: View {
    let year: Int
    let summary: YearSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "\(year)年")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Label("\(summary.prefectureCount)県", systemImage: "map")
                Label("\(summary.visitCount)回", systemImage: "figure.walk")
                if let farthest = summary.farthestPrefectureName {
                    Label(farthest, systemImage: "location.north.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .textCase(nil)
    }
}

// MARK: - VisitRow

private struct VisitRow: View {
    let visit: Visit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.prefectureName)
                    .font(.body)
                if !visit.note.isEmpty {
                    Text(visit.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(dateLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var dateLabel: String {
        let start = slashDateFormatter.string(from: visit.startDate)
        if Calendar.current.isDate(visit.startDate, inSameDayAs: visit.effectiveEndDate) {
            return start
        }
        return "\(start)〜\(slashDateFormatter.string(from: visit.effectiveEndDate))"
    }
}

// MARK: - EditVisitView

/// 訪問記録を編集するシート
struct EditVisitView: View {
    @Bindable var visit: Visit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var selectedPrefectureName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var note = ""
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

                Section("旅行期間") {
                    TravelDatePicker(startDate: $startDate, endDate: $endDate)
                }

                Section("メモ（任意）") {
                    TextField("メモ", text: $note)
                }

                Section {
                    Button("この記録を削除", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .onAppear {
                selectedPrefectureName = visit.prefectureName
                startDate = visit.startDate
                endDate = visit.effectiveEndDate
                note = visit.note
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
                }
            }
            .confirmationDialog("この記録を削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    modelContext.delete(visit)
                    dismiss()
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private func save() {
        visit.prefectureName = selectedPrefectureName
        visit.startDate = startDate
        visit.endDate = Calendar.current.isDate(startDate, inSameDayAs: endDate) ? nil : endDate
        visit.note = note
        visit.prefecture = prefectures.first { $0.name == selectedPrefectureName }
        dismiss()
    }
}

// MARK: - AddVisitView

struct AddVisitView: View {
    var initialPrefectureName: String = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var selectedPrefectureName = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var note = ""

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

                Section("旅行期間") {
                    TravelDatePicker(startDate: $startDate, endDate: $endDate)
                }

                Section("メモ（任意）") {
                    TextField("メモ", text: $note)
                }
            }
            .scrollContentBackground(.hidden)
            .onAppear {
                if !initialPrefectureName.isEmpty {
                    selectedPrefectureName = initialPrefectureName
                } else if selectedPrefectureName.isEmpty, let first = prefectures.first {
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
                }
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private func save() {
        let effectiveEnd = Calendar.current.isDate(startDate, inSameDayAs: endDate) ? nil : endDate
        let visit = Visit(prefectureName: selectedPrefectureName, startDate: startDate, endDate: effectiveEnd, note: note)
        visit.prefecture = prefectures.first { $0.name == selectedPrefectureName }
        modelContext.insert(visit)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    NavigationStack {
        TimelineView(mapViewModel: vm)
    }
    .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
