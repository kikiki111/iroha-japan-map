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
    @State private var selectedVisit: Visit?

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
            .sheet(item: $selectedVisit) { visit in
                VisitDetailView(visit: visit)
                    .presentationDetents([.medium])
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
                                    selectedVisit = visit
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

private let jaDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M/d"
    return f
}()

private let jaSingleDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M月d日"
    return f
}()

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
        if Calendar.current.isDate(visit.startDate, inSameDayAs: visit.effectiveEndDate) {
            return jaSingleDateFormatter.string(from: visit.startDate)
        }
        return "\(jaDateFormatter.string(from: visit.startDate))〜\(jaDateFormatter.string(from: visit.effectiveEndDate))"
    }
}

// MARK: - VisitDetailView

/// 訪問記録の詳細を表示するシート
struct VisitDetailView: View {
    let visit: Visit

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("都道府県")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(visit.prefectureName)
                    }
                    HStack {
                        Text("出発日")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(jaSingleDateFormatter.string(from: visit.startDate))
                    }
                    if let endDate = visit.endDate {
                        HStack {
                            Text("帰着日")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(jaSingleDateFormatter.string(from: endDate))
                        }
                    }
                }
                if !visit.note.isEmpty {
                    Section("メモ") {
                        Text(visit.note)
                    }
                }
            }
            .navigationTitle("旅の記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - AddVisitView

struct AddVisitView: View {
    var initialPrefectureName: String = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var selectedPrefectureName = ""
    @State private var travelDates: Set<DateComponents> = []
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

                Section("旅行日（複数選択可）") {
                    MultiDatePicker("旅行日を選択", selection: $travelDates)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                Section("メモ（任意）") {
                    TextField("メモ", text: $note)
                }
            }
            .onAppear {
                if !initialPrefectureName.isEmpty {
                    selectedPrefectureName = initialPrefectureName
                } else if selectedPrefectureName.isEmpty, let first = prefectures.first {
                    selectedPrefectureName = first.name
                }
                // デフォルトで今日を選択
                if travelDates.isEmpty {
                    let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    travelDates = [today]
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
                        .disabled(selectedPrefectureName.isEmpty || travelDates.isEmpty)
                }
            }
        }
    }

    private func save() {
        let calendar = Calendar.current
        let sortedDates = travelDates.compactMap { calendar.date(from: $0) }.sorted()
        guard let startDate = sortedDates.first else { return }
        let endDate = sortedDates.count > 1 ? sortedDates.last : nil

        let visit = Visit(
            prefectureName: selectedPrefectureName,
            startDate: startDate,
            endDate: endDate,
            note: note
        )
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
