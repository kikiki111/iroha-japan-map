//
//  TimelineView.swift
//  Iroha
//

import SwiftUI
import SwiftData

/// 訪問履歴を年月でグループ分けして表示するタイムラインビュー
struct TimelineView: View {
    var mapViewModel: MapViewModel

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]

    @State private var isShowingAddVisit = false

    // MARK: Grouping

    private var visitsByYear: [(year: Int, visits: [Visit])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: visits) {
            calendar.component(.year, from: $0.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (year: $0.key, visits: $0.value) }
    }

    private func visitsByMonth(in yearVisits: [Visit]) -> [(month: Int, visits: [Visit])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: yearVisits) {
            calendar.component(.month, from: $0.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (month: $0.key, visits: $0.value.sorted { $0.date > $1.date }) }
    }

    // MARK: Body

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

    // MARK: Subviews

    private var visitList: some View {
        List {
            ForEach(visitsByYear, id: \.year) { group in
                Section {
                    ForEach(visitsByMonth(in: group.visits), id: \.month) { monthGroup in
                        monthSection(monthGroup.month, visits: monthGroup.visits)
                    }
                } header: {
                    YearHeaderView(year: group.year, visits: group.visits)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func monthSection(_ month: Int, visits: [Visit]) -> some View {
        let monthLabel = monthName(month)
        Section(monthLabel) {
            ForEach(visits) { visit in
                VisitRow(visit: visit) {
                    mapViewModel.focus(prefecture: visit.prefectureName)
                }
            }
            .onDelete { offsets in deleteVisits(offsets, from: visits) }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("訪問記録がありません", systemImage: "map")
        } description: {
            Text("＋ボタンから訪問した都道府県を追加しましょう。")
        }
    }

    // MARK: Helpers

    private func monthName(_ month: Int) -> String {
        "\(month)月"
    }

    private func deleteVisits(_ offsets: IndexSet, from source: [Visit]) {
        for index in offsets {
            modelContext.delete(source[index])
        }
    }
}

// MARK: - YearHeaderView

private struct YearHeaderView: View {
    let year: Int
    let visits: [Visit]

    private var uniquePrefectureCount: Int {
        Set(visits.map { $0.prefectureName }).count
    }

    private var farthestPrefecture: String? {
        visits
            .compactMap { visit -> (name: String, distance: Double)? in
                guard let pref = Prefecture.named(visit.prefectureName) else { return nil }
                return (name: pref.name, distance: pref.distanceFromTokyo)
            }
            .max(by: { $0.distance < $1.distance })
            .map { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(year)年")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Label("\(uniquePrefectureCount)県", systemImage: "mappin.and.ellipse")
                Label("\(visits.count)回", systemImage: "figure.walk")
                if let farthest = farthestPrefecture {
                    Label(farthest, systemImage: "location.north.line")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }
}

// MARK: - VisitRow

private struct VisitRow: View {
    let visit: Visit
    let onTap: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(visit.prefectureName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(Self.dateFormatter.string(from: visit.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !visit.note.isEmpty {
                        Text(visit.note)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "map")
                    .foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AddVisitView

private struct AddVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedPrefecture = Prefecture.all.first?.name ?? ""
    @State private var date = Date()
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("都道府県") {
                    Picker("都道府県", selection: $selectedPrefecture) {
                        ForEach(Prefecture.all) { pref in
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
            .navigationTitle("訪問を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
        }
    }

    private func save() {
        let visit = Visit(prefectureName: selectedPrefecture, date: date, note: note)
        modelContext.insert(visit)
        dismiss()
    }
}
