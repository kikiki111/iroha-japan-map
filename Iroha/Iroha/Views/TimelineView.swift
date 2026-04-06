//
//  TimelineView.swift
//  Iroha
//

import SwiftUI
import SwiftData

// MARK: - TimelineView

struct TimelineView: View {
    @Query(sort: \Visit.date, order: .reverse) private var visits: [Visit]
    @ObservedObject var mapViewModel: MapViewModel

    // MARK: Computed grouping

    /// Visits grouped by year, then by month, in descending order.
    private var visitsByYear: [YearGroup] {
        let calendar = Calendar.current

        // Build a dictionary keyed by (year, month)
        var byYearMonth: [Int: [Int: [Visit]]] = [:]
        for visit in visits {
            let year  = calendar.component(.year,  from: visit.date)
            let month = calendar.component(.month, from: visit.date)
            byYearMonth[year, default: [:]][month, default: []].append(visit)
        }

        // Sort years descending; within each year sort months descending
        return byYearMonth
            .keys
            .sorted(by: >)
            .map { year in
                let monthDict = byYearMonth[year] ?? [:]
                let monthGroups = monthDict
                    .keys
                    .sorted(by: >)
                    .map { month in
                        MonthGroup(
                            year: year,
                            month: month,
                            visits: (monthDict[month] ?? []).sorted { $0.date > $1.date }
                        )
                    }
                return YearGroup(year: year, monthGroups: monthGroups)
            }
    }

    // MARK: Body

    var body: some View {
        List {
            ForEach(visitsByYear) { yearGroup in
                Section {
                    ForEach(yearGroup.monthGroups) { monthGroup in
                        // Month divider row (non-tappable)
                        Text(monthGroup.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color(.systemGroupedBackground))

                        // Visit rows for this month
                        ForEach(monthGroup.visits) { visit in
                            VisitRow(visit: visit)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if let prefecture = Prefecture.find(byName: visit.prefectureName) {
                                        mapViewModel.focus(prefecture: prefecture)
                                    }
                                }
                        }
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
        .navigationTitle("タイムライン")
    }

    private func yearSummary(for year: Int) -> YearSummary {
        let calendar = Calendar.current
        let yearVisits = visits.filter {
            calendar.component(.year, from: $0.date) == year
        }

        let uniquePrefectures = Set(yearVisits.map(\.prefectureName))
        let farthest = uniquePrefectures
            .compactMap { Prefecture.find(byName: $0) }
            .max(by: { $0.distanceFromTokyo < $1.distanceFromTokyo })

        return YearSummary(
            visitCount: yearVisits.count,
            prefectureCount: uniquePrefectures.count,
            farthestPrefectureName: farthest?.name
        )
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
    /// Unique across all years by combining year and month.
    var id: String { "\(year)-\(month)" }

    var label: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月"
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        // Defensive guard: year and month are derived from real visit dates,
        // so Calendar.date(from:) is not expected to return nil in practice.
        guard let date = Calendar.current.date(from: components) else {
            return "\(year)年\(month)月"
        }
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

// MARK: - Preview

#Preview {
    @Previewable @StateObject var vm = MapViewModel()
    NavigationStack {
        TimelineView(mapViewModel: vm)
    }
    .modelContainer(for: Visit.self, inMemory: true)
}
