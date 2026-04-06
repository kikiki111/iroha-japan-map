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
    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var isShowingAddVisit = false

    // MARK: - Prefecture lookup

    private func findPrefecture(byName name: String) -> Prefecture? {
        prefectures.first { $0.name == name }
    }

    // MARK: - Grouping

    private var visitsByYear: [YearGroup] {
        let calendar = Calendar.current
        var byYearMonth: [Int: [Int: [Visit]]] = [:]
        for visit in visits {
            let year  = calendar.component(.year,  from: visit.date)
            let month = calendar.component(.month, from: visit.date)
            byYearMonth[year, default: [:]][month, default: []].append(visit)
        }
        return byYearMonth.keys.sorted(by: >).map { year in
            let monthDict   = byYearMonth[year] ?? [:]
            let monthGroups = monthDict.keys.sorted(by: >).map { month in
                MonthGroup(
                    year: year,
                    month: month,
                    visits: (monthDict[month] ?? []).sorted { $0.date > $1.date }
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
                                    if let pref = findPrefecture(byName: visit.prefectureName) {
                                        mapViewModel.focus(prefecture: pref)
                                    }
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
        let yearVisits  = visits.filter { calendar.component(.year, from: $0.date) == year }
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
        var components   = DateComponents()
        components.year  = year
        components.month = month
        components.day   = 1
        guard let date = Calendar.current.date(from: components) else {
            return "\(year)年\(month)月"
        }
        let formatter        = DateFormatter()
        formatter.locale     = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月"
        return formatter.string(from: date)
    }
}

struct YearSummary {
    let visitCount: Int
    let prefectureCount: Int
    let farthestPrefectureName: String?
}

// MARK: - YearHeaderView

struct YearHeaderView: View {
    let year: Int
    let summary: YearSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(year)年")
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
        .padding(.vertical, 6)
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
            Text(visit.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddVisitView

private struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]

    @State private var selectedPrefectureName = ""
    @State private var date = Date()
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

                Section("日付") {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                Section("メモ（任意）") {
                    TextField("メモ", text: $note)
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
                }
            }
        }
    }

    private func save() {
        let visit = Visit(prefectureName: selectedPrefectureName, date: date, note: note)
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
