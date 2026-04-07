//
//  StatisticsTabView.swift
//  Iroha
//

import SwiftUI
import SwiftData
import Charts

/// 旅行統計を表示するタブ
struct StatisticsTabView: View {
    @Query(sort: \Prefecture.id) private var prefectures: [Prefecture]
    @Query(sort: \Visit.startDate) private var visits: [Visit]

    @State private var selectedYear: Int?

    private var visitedCount: Int { prefectures.filter(\.isVisited).count }
    private var totalVisits: Int { visits.count }
    private var totalDays: Int {
        visits.reduce(0) { sum, visit in
            let days = Calendar.current.dateComponents([.day], from: visit.startDate, to: visit.effectiveEndDate).day ?? 0
            return sum + max(days, 1)
        }
    }
    private var conquestRate: Double { Double(visitedCount) / 47.0 * 100 }

    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(visits.map { calendar.component(.year, from: $0.startDate) })
        return years.sorted(by: >)
    }

    /// 訪問ごとの累積旅行回数（常に増加するデータ）
    private var visitProgression: [VisitDataPoint] {
        let sorted = visits.sorted { $0.startDate < $1.startDate }
        let calendar = Calendar.current
        var result: [VisitDataPoint] = []
        var cumulative = 0

        for visit in sorted {
            cumulative += 1
            let day = calendar.startOfDay(for: visit.startDate)
            if let lastIdx = result.indices.last, calendar.isDate(result[lastIdx].date, inSameDayAs: day) {
                result[lastIdx] = VisitDataPoint(date: day, count: cumulative)
            } else {
                result.append(VisitDataPoint(date: day, count: cumulative))
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if visits.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 20) {
                        allTimeSection
                        if !visits.isEmpty {
                            visitProgressionSection
                        }
                        if !availableYears.isEmpty {
                            yearlySection
                        }
                        regionSection
                    }
                    .padding()
                }
            }
            .background(Color.irohaBackground)
            .navigationTitle("統計")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("旅行記録がありません", systemImage: "chart.bar")
        } description: {
            Text("訪問を追加すると統計が表示されます。")
        }
    }

    // MARK: - All-time

    private var allTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("全期間統計")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatCard(icon: "airplane", label: "総旅行回数", value: "\(totalVisits)", unit: "回", color: Color(hex: "#7F77DD"))
                StatCard(icon: "calendar", label: "総旅行日数", value: "\(totalDays)", unit: "日", color: Color(hex: "#9F97DD"))
                StatCard(icon: "map", label: "訪問済み県", value: "\(visitedCount)", unit: "県", color: Color(hex: "#AFA9EC"))
                StatCard(icon: "target", label: "制覇率", value: String(format: "%.1f", conquestRate), unit: "%", color: Color(hex: "#534AB7"))
            }
        }
    }

    // MARK: - Yearly

    private var yearlySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("年度別統計")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("年", selection: Binding(
                get: { selectedYear ?? availableYears.first ?? 0 },
                set: { selectedYear = $0 }
            )) {
                ForEach(availableYears, id: \.self) { year in
                    Text(verbatim: "\(year)年").tag(year)
                }
            }
            .pickerStyle(.segmented)

            let year = selectedYear ?? availableYears.first ?? 0
            let yearVisits = visits.filter { Calendar.current.component(.year, from: $0.startDate) == year }
            let yearDays = yearVisits.reduce(0) { sum, visit in
                let days = Calendar.current.dateComponents([.day], from: visit.startDate, to: visit.effectiveEndDate).day ?? 0
                return sum + max(days, 1)
            }
            let yearPrefectures = Set(yearVisits.map(\.prefectureName)).count

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatCard(icon: "airplane", label: "旅行回数", value: "\(yearVisits.count)", unit: "回", color: Color(hex: "#7F77DD"))
                StatCard(icon: "calendar", label: "旅行日数", value: "\(yearDays)", unit: "日", color: Color(hex: "#9F97DD"))
                StatCard(icon: "map", label: "訪問県数", value: "\(yearPrefectures)", unit: "県", color: Color(hex: "#AFA9EC"))
            }
        }
    }

    // MARK: - Visit progression chart

    private var visitProgressionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("旅行回数の推移")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Chart(visitProgression) { point in
                LineMark(
                    x: .value("日付", point.date),
                    y: .value("回数", point.count)
                )
                .foregroundStyle(Color(hex: "#7F77DD"))
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("日付", point.date),
                    y: .value("回数", point.count)
                )
                .foregroundStyle(Color(hex: "#7F77DD"))
                .symbolSize(30)
            }
            .chartYScale(domain: 0...(totalVisits + 2))
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let cal = Calendar.current
                            let m = cal.component(.month, from: date)
                            let d = cal.component(.day, from: date)
                            if m == 1 && d == 1 {
                                let y = cal.component(.year, from: date)
                                Text(verbatim: "\(y)年")
                            } else {
                                Text(verbatim: "\(m)/\(d)")
                            }
                        }
                    }
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 3600 * 24 * 730)
            .frame(height: 180)
            .padding()
            .background(Color.irohaBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Region breakdown

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("地方別訪問数")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(Region.allCases) { region in
                let group = prefectures.filter { $0.region == region }
                let visited = group.filter(\.isVisited).count
                let total = group.count
                let ratio = total > 0 ? Double(visited) / Double(total) : 0

                DisclosureGroup {
                    ForEach(group) { pref in
                        HStack {
                            Image(systemName: pref.isVisited ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(pref.isVisited ? region.color : Color(.systemGray4))
                                .font(.subheadline)
                            Text(pref.name)
                                .font(.subheadline)
                            Spacer()
                            if pref.isVisited {
                                Text(verbatim: "\(pref.visits.count)回")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(region.localizedName)
                            .font(.caption)
                            .frame(width: 44, alignment: .leading)
                        ProgressView(value: ratio)
                            .tint(region.color)
                        Text(verbatim: "\(visited)/\(total)")
                            .font(.caption)
                            .monospacedDigit()
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }
            .padding()
            .background(Color.irohaBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - VisitDataPoint

private struct VisitDataPoint: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

// MARK: - StatCard

private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    StatisticsTabView()
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
