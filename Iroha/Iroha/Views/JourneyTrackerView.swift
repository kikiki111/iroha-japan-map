//
//  JourneyTrackerView.swift
//  Iroha
//
//  旅の軌跡タブ：旅の進捗ダッシュボード

import SwiftUI
import SwiftData
import Charts

struct JourneyTrackerView: View {
    private var prefectures: [Prefecture] { Prefecture.all }
    @Query(sort: \Visit.startDate, order: .reverse) private var visits: [Visit]
    private var stats: VisitStats { VisitStats(visits: visits) }

    @State private var selectedYear: Int = 0
    @State private var showDistanceInfo = false
    @State private var highlightTrip: Trip?
    @State private var highlightPrefecture: Prefecture?
    @State private var editingVisit: Visit?
    @State private var chartPeriod: ChartPeriod = .year
    @State private var chartMetric: ChartMetric = .visitCount
    @State private var chartScrollPosition: Date = Calendar.current.dateInterval(of: .year, for: Date())?.start ?? Date()

    // MARK: - Cumulative (all-time)

    private var visitedCount: Int { stats.visitedCount }

    // MARK: - Year filter

    private var availableYears: [Int] {
        let calendar = Calendar.current
        return Set(visits.map { calendar.component(.year, from: $0.startDate) }).sorted(by: >)
    }

    /// 旅行記録のみ（旅数・距離・最遠地などの集計はすべてこちら起点）
    private var travelVisits: [Visit] {
        visits.filter { !$0.isResidence }
    }

    private var filteredVisits: [Visit] {
        if selectedYear == 0 { return travelVisits }
        return travelVisits.filter { Calendar.current.component(.year, from: $0.startDate) == selectedYear }
    }

    /// 選択中の期間に住みはじめた県の数（「すべて」選択時は全期間）
    private var filteredResidenceCount: Int {
        let residences = visits.filter(\.isResidence)
        if selectedYear == 0 {
            return Set(residences.map(\.prefectureID)).count
        }
        let inYear = residences.filter {
            Calendar.current.component(.year, from: $0.startDate) == selectedYear
        }
        return Set(inYear.map(\.prefectureID)).count
    }

    /// 居住したことのある都道府県 ID（地方別リストの家アイコン用、期間フィルタなし）
    private var residencePrefectureIDs: Set<Int> {
        Set(visits.filter(\.isResidence).map(\.prefectureID))
    }

    private var filteredTotalVisits: Int { filteredVisits.count }

    private var filteredTripCount: Int {
        filteredTrips.count
    }

    private var filteredTrips: [Trip] {
        TripDetector.detect(from: filteredVisits)
    }

    private var chartDateRange: (start: Date, end: Date) {
        chartDomainRange(period: chartPeriod, selectedYear: selectedYear)
    }

    private func chartReferenceEnd(selectedYear year: Int, period: ChartPeriod) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        if year > 0 && year != currentYear {
            return calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? now
        }

        switch period {
        case .week:
            let weekEnd = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
            return calendar.date(byAdding: .day, value: -1, to: weekEnd) ?? now
        case .month:
            let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
            return calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? now
        case .year, .all:
            let targetYear = year > 0 ? year : currentYear
            return calendar.date(from: DateComponents(year: targetYear, month: 12, day: 31)) ?? now
        }
    }

    private func chartDomainRange(period: ChartPeriod, selectedYear year: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let referenceEnd = chartReferenceEnd(selectedYear: year, period: period)

        if year > 0 {
            let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? referenceEnd
            return (yearStart, referenceEnd)
        }

        let earliest = visits.map(\.startDate).min() ?? referenceEnd
        let start: Date
        switch period {
        case .week:
            start = calendar.dateInterval(of: .weekOfYear, for: earliest)?.start ?? earliest
        case .month:
            start = calendar.dateInterval(of: .month, for: earliest)?.start ?? earliest
        case .year, .all:
            start = calendar.dateInterval(of: .year, for: earliest)?.start ?? earliest
        }

        return (start, referenceEnd)
    }

    private var chartVisibleDomainLength: TimeInterval {
        switch chartPeriod {
        case .week:  return 3600 * 24 * 7
        case .month: return 3600 * 24 * 31
        case .year:  return 3600 * 24 * 365
        case .all:   return 3600 * 24 * 365
        }
    }

    private var chartVisibleDateRange: (start: Date, end: Date) {
        let domain = chartDateRange
        let latestStart = latestScrollStart(period: chartPeriod, selectedYear: selectedYear)
        let upperBound = max(latestStart, domain.start)
        let start = min(max(chartScrollPosition, domain.start), upperBound)
        let end = min(addVisibleLength(to: start, period: chartPeriod), domain.end)
        return (start, end)
    }

    private func latestScrollStart(period: ChartPeriod, selectedYear year: Int) -> Date {
        let calendar = Calendar.current
        let domain = chartDomainRange(period: period, selectedYear: year)
        let referenceEnd = domain.end
        let start: Date
        switch period {
        case .week:
            start = calendar.dateInterval(of: .weekOfYear, for: referenceEnd)?.start ?? referenceEnd
        case .month:
            start = calendar.dateInterval(of: .month, for: referenceEnd)?.start ?? referenceEnd
        case .year:
            start = calendar.dateInterval(of: .year, for: referenceEnd)?.start ?? referenceEnd
        case .all:
            start = calendar.date(byAdding: .year, value: -1, to: referenceEnd) ?? referenceEnd
        }
        return max(start, domain.start)
    }

    private func addVisibleLength(to date: Date, period: ChartPeriod) -> Date {
        let calendar = Calendar.current
        switch period {
        case .week:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .year, .all:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    private func chartExtendedEnd(for end: Date) -> Date {
        let calendar = Calendar.current
        switch chartPeriod {
        case .week, .month:
            return calendar.date(byAdding: .day, value: 1, to: end) ?? end
        case .year, .all:
            return calendar.date(byAdding: .month, value: 1, to: end) ?? end
        }
    }

    private func resetChartScrollPosition(period: ChartPeriod, selectedYear year: Int) {
        chartScrollPosition = latestScrollStart(period: period, selectedYear: year)
    }

    private var chartData: [JourneyDataPoint] {
        let calendar = Calendar.current
        let range = chartDateRange
        let visitsInRange: [Visit]
        if chartPeriod == .all {
            visitsInRange = filteredVisits
        } else {
            visitsInRange = filteredVisits.filter { $0.startDate >= range.start && $0.startDate <= range.end }
        }

        switch chartPeriod {
        case .week:
            var days: [Date: Int] = [:]
            for visit in visitsInRange {
                let day = calendar.startOfDay(for: visit.startDate)
                days[day, default: 0] += 1
            }
            var result: [JourneyDataPoint] = []
            var current = range.start
            while current <= range.end {
                result.append(JourneyDataPoint(date: current, count: days[current] ?? 0))
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
            }
            return result

        case .month:
            var days: [Date: Int] = [:]
            for visit in visitsInRange {
                let day = calendar.startOfDay(for: visit.startDate)
                days[day, default: 0] += 1
            }
            var result: [JourneyDataPoint] = []
            var current = range.start
            while current <= range.end {
                result.append(JourneyDataPoint(date: current, count: days[current] ?? 0))
                current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
            }
            return result

        case .year:
            var months: [Date: Int] = [:]
            for visit in visitsInRange {
                let comps = calendar.dateComponents([.year, .month], from: visit.startDate)
                let monthStart = calendar.date(from: comps) ?? visit.startDate
                months[monthStart, default: 0] += 1
            }
            var result: [JourneyDataPoint] = []
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: range.start)) ?? range.start
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: range.end)) ?? range.end
            while current <= endMonth {
                result.append(JourneyDataPoint(date: current, count: months[current] ?? 0))
                current = calendar.date(byAdding: .month, value: 1, to: current) ?? current.addingTimeInterval(86400 * 30)
            }
            return result

        case .all:
            var months: [Date: Int] = [:]
            for visit in visitsInRange {
                let comps = calendar.dateComponents([.year, .month], from: visit.startDate)
                let monthStart = calendar.date(from: comps) ?? visit.startDate
                months[monthStart, default: 0] += 1
            }
            var result: [JourneyDataPoint] = []
            var current = calendar.date(from: calendar.dateComponents([.year, .month], from: range.start)) ?? range.start
            let endMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: range.end)) ?? range.end
            while current <= endMonth {
                result.append(JourneyDataPoint(date: current, count: months[current] ?? 0))
                current = calendar.date(byAdding: .month, value: 1, to: current) ?? current.addingTimeInterval(86400 * 30)
            }
            return result
        }
    }

    private var prefectureChartData: [JourneyDataPoint] {
        let sorted = filteredVisits.sorted { $0.startDate < $1.startDate }
        let calendar = Calendar.current
        let range = chartDateRange
        var seen = Set<String>()
        var cumulative = 0
        var points: [JourneyDataPoint] = [JourneyDataPoint(date: range.start, count: 0)]

        for visit in sorted {
            guard visit.startDate >= range.start, visit.startDate <= range.end else { continue }
            if seen.insert(visit.prefectureName).inserted {
                cumulative += 1
            }
            let day = calendar.startOfDay(for: visit.startDate)
            if let lastIdx = points.indices.last, calendar.isDate(points[lastIdx].date, inSameDayAs: day) {
                points[lastIdx] = JourneyDataPoint(date: day, count: cumulative)
            } else {
                points.append(JourneyDataPoint(date: day, count: cumulative))
            }
        }

        if let last = points.last, !calendar.isDate(last.date, inSameDayAs: range.end) {
            points.append(JourneyDataPoint(date: range.end, count: cumulative))
        }
        return points
    }

    private var prefectureChartMaxY: Int {
        let maxCount = prefectureChartData.map(\.count).max() ?? 0
        return max(maxCount + 2, 3)
    }

    private func filteredVisitCount(for prefecture: Prefecture) -> Int {
        filteredVisits.filter { $0.prefectureName == prefecture.name }.count
    }

    // MARK: - Year highlights

    private var firstTripOfYear: Trip? {
        filteredTrips.min { $0.startDate < $1.startDate }
    }

    private var newPrefectureCountInYear: Int {
        let currentNames = Set(filteredVisits.map(\.prefectureName))
        guard selectedYear > 0 else { return currentNames.count }
        let beforeYear = visits.filter {
            Calendar.current.component(.year, from: $0.startDate) < selectedYear
        }
        let previousNames = Set(beforeYear.map(\.prefectureName))
        return currentNames.subtracting(previousNames).count
    }

    private var filteredConqueredRegionCount: Int {
        // 居住県も「訪れた」に含める（地図・統計バーと同じ扱い）
        let residenceIDs = residencePrefectureIDs
        let visitedNames = Set(filteredVisits.map(\.prefectureName))
        return Region.allCases.filter { region in
            let group = prefectures.filter { $0.region == region }
            return !group.isEmpty && group.allSatisfy {
                visitedNames.contains($0.name) || residenceIDs.contains($0.id)
            }
        }.count
    }

    private var mostVisitedInPeriod: (prefecture: Prefecture, count: Int)? {
        let grouped = Dictionary(grouping: filteredVisits, by: \.prefectureName)
        guard let top = grouped.max(by: { $0.value.count < $1.value.count }),
              let pref = prefectures.first(where: { $0.name == top.key }) else { return nil }
        return (pref, top.value.count)
    }

    private func tripContaining(_ visit: Visit) -> Trip? {
        filteredTrips.first { trip in
            trip.visits.contains { $0.id == visit.id }
        }
    }

    private var tokyo: Prefecture? {
        prefectures.first { $0.id == 13 }
    }

    private func distanceFromTokyo(_ target: Prefecture) -> Double {
        guard let tokyo else { return target.distanceFromTokyo }
        return DistanceCalculator.distance(from: tokyo, to: target)
    }

    private var totalDistance: Int {
        guard let tokyo else { return 0 }
        return Int(DistanceCalculator.totalRouteDistance(trips: filteredTrips, home: tokyo, prefectures: prefectures))
    }

    private var farthestPrefecture: Prefecture? {
        let visitedNames = Set(filteredVisits.map(\.prefectureName))
        return prefectures
            .filter { visitedNames.contains($0.name) }
            .max { distanceFromTokyo($0) < distanceFromTokyo($1) }
    }

    private var farthestDistance: Int {
        guard let farthest = farthestPrefecture else { return 0 }
        return Int(distanceFromTokyo(farthest))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    yearSelector
                    if !filteredVisits.isEmpty {
                        yearHighlightCard
                    }
                    threeColumnStats
                    regionBreakdownSection
                    travelDistanceSection
                    visitProgressionSection
                }
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $highlightTrip) { trip in
                TripDetailSheet(trip: trip, prefectures: prefectures) { visit in
                    highlightTrip = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editingVisit = visit
                    }
                }
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $editingVisit) { visit in
                VisitFormView(prefectures: Array(prefectures), prefecture: nil, editingVisit: visit)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $highlightPrefecture) { prefecture in
                PrefectureDetailSheet(prefecture: prefecture)
                    .presentationDetents([.fraction(0.70), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
                    .presentationBackground(Color.irohaWashi)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("記録")
                        .font(.system(size: 20, weight: .light, design: .serif))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.irohaSumi2)
                    }
                }
            }
        }
    }

    // MARK: - Year highlight card

    private var yearHighlightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: selectedYear > 0 ? "\(selectedYear)年の旅" : "すべての旅")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                // 初旅
                if let firstTrip = firstTripOfYear,
                   let firstVisit = firstTrip.visits.min(by: { $0.startDate < $1.startDate }) {
                    highlightRow(
                        icon: "airplane.departure",
                        label: "初旅",
                        value: "\(firstVisit.startDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP")))) \u{00B7} \(firstVisit.prefectureName)",
                        thumbnail: firstVisit.sortedPhotoThumbnails.first
                    ) {
                        highlightTrip = firstTrip
                    }
                } else {
                    highlightPlaceholderRow(icon: "airplane.departure", label: "初旅")
                }
                Divider().padding(.leading, 36)

                // 最遠地
                if let farthest = farthestPrefecture, farthestDistance > 0 {
                    let farthestVisit = filteredVisits
                        .filter { $0.prefectureName == farthest.name }
                        .min { $0.startDate < $1.startDate }
                    highlightRow(
                        icon: "mappin.and.ellipse",
                        label: "最遠地",
                        value: "\(farthest.name)（\(farthestDistance.formatted()) km）",
                        thumbnail: farthestVisit?.sortedPhotoThumbnails.first
                    ) {
                        if let visit = farthestVisit, let trip = tripContaining(visit) {
                            highlightTrip = trip
                        } else {
                            highlightPrefecture = farthest
                        }
                    }
                } else {
                    highlightPlaceholderRow(icon: "mappin.and.ellipse", label: "最遠地")
                }
                Divider().padding(.leading, 36)

                // 新規 / 旅行
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.irohaFuji)
                        .frame(width: 22)
                    Text(selectedYear > 0 ? "新規" : "訪問県")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.irohaSumi3)
                        .frame(width: 42, alignment: .leading)
                    Text(newPrefectureCountInYear > 0 ? "\(newPrefectureCountInYear)県" : "—")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(newPrefectureCountInYear > 0 ? .irohaSumi : .irohaSumi3)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.vertical, 8)
                Divider().padding(.leading, 36)

                // 最多
                if let top = mostVisitedInPeriod, top.count >= 1 {
                    let topVisit = filteredVisits
                        .filter { $0.prefectureName == top.prefecture.name }
                        .max { $0.startDate < $1.startDate }
                    highlightRow(
                        icon: "heart.fill",
                        label: "最多",
                        value: "\(top.prefecture.name)（\(top.count)回）",
                        thumbnail: topVisit?.sortedPhotoThumbnails.first
                    ) {
                        highlightPrefecture = top.prefecture
                    }
                } else {
                    highlightPlaceholderRow(icon: "heart.fill", label: "最多")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.irohaCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.irohaWashi3, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
        }
    }

    private func highlightRow(
        icon: String,
        label: String,
        value: String,
        thumbnail: Data?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.irohaFuji)
                    .frame(width: 22)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.irohaSumi3)
                    .frame(width: 36, alignment: .leading)

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.irohaSumi)

                Spacer()

                Group {
                    if let thumbData = thumbnail,
                       let uiImage = UIImage(data: thumbData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.irohaSumi3.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func highlightPlaceholderRow(icon: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.irohaFuji.opacity(0.4))
                .frame(width: 22)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.irohaSumi3)
                .frame(width: 36, alignment: .leading)
            Text("—")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.irohaSumi3)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Hero section

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("全国制覇")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)

            HStack(alignment: .bottom, spacing: 6) {
                NurikakeNumber(value: visitedCount, fontSize: 56, ratio: Double(visitedCount) / 47.0)
                Text("/ 47")
                    .font(.system(size: 16))
                    .foregroundColor(.irohaSumi3)
                    .padding(.bottom, 6)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.irohaWashi3)
                        .frame(height: 7)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.irohaFujiLt, .irohaFuji, .irohaFujiDk],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(visitedCount) / 47.0, height: 7)
                }
            }
            .frame(height: 7)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
    }

    // MARK: - Year selector

    private var yearSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    yearTab("すべて", year: 0)
                    ForEach(availableYears, id: \.self) { year in
                        yearTab("\(year)", year: year)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 10)
    }

    private func yearTab(_ label: String, year: Int) -> some View {
        let isActive = selectedYear == year
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedYear = year
                resetChartScrollPosition(period: chartPeriod, selectedYear: year)
            }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                .foregroundColor(isActive ? .white : .irohaSumi2)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isActive ? Color.irohaFujiDk : Color.irohaWashi2)
                .clipShape(Capsule())
        }
        .id(year)
    }

    // MARK: - 3-column stats

    private var threeColumnStats: some View {
        HStack(spacing: 0) {
            profileColumn(value: filteredTotalVisits, label: "記録数")
            Divider().frame(height: 40)
            profileColumn(value: filteredTripCount, label: "旅数")
            // 居住が 1 件もないユーザーには列を出さない（従来の 3 列のまま）
            if filteredResidenceCount > 0 {
                Divider().frame(height: 40)
                // 他の列と同じ書式のまま、色だけ金茶にして区別する
                profileColumn(value: filteredResidenceCount, label: "住んだ県",
                              valueColor: .irohaSumikaDk)
            }
            Divider().frame(height: 40)
            profileColumn(value: filteredConqueredRegionCount, label: "地方制覇")
        }
        .padding(.vertical, 10)
        .background(Color.irohaCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.irohaWashi3, lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func profileColumn(value: Int, label: String,
                               valueColor: Color = .irohaFujiDk) -> some View {
        VStack(spacing: 3) {
            Text(verbatim: "\(value)")
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(valueColor)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.irohaSumi3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Region breakdown

    private var regionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("地方別")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 14)

            VStack(spacing: 0) {
                ForEach(Region.allCases) { region in
                    let residenceIDs = residencePrefectureIDs
                    let group = prefectures.filter { $0.region == region }
                    let total = group.count
                    // 居住県も「その地方を訪れた」に含める（地図・統計バーと同じ扱い）
                    let visitedInPeriod = group.filter {
                        filteredVisitCount(for: $0) > 0 || residenceIDs.contains($0.id)
                    }.count
                    let ratio = total > 0 ? Double(visitedInPeriod) / Double(total) : 0.0

                    DisclosureGroup {
                        VStack(spacing: 0) {
                            ForEach(group) { pref in
                                let count = filteredVisitCount(for: pref)
                                let isResidence = residenceIDs.contains(pref.id)
                                HStack(spacing: 8) {
                                    Image(systemName: (count > 0 || isResidence) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13))
                                        .foregroundColor((count > 0 || isResidence) ? .irohaFuji : .irohaSumi3.opacity(0.4))
                                    Text(pref.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(.irohaSumi)
                                    if isResidence {
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.irohaSumika)
                                            .accessibilityLabel("住んだ県")
                                    }
                                    Spacer()
                                    if count > 0 {
                                        Text(verbatim: "\(count)回")
                                            .font(.system(size: 11))
                                            .foregroundColor(.irohaSumi3)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.leading, 4)
                    } label: {
                        HStack(spacing: 8) {
                            Text(region.localizedName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.irohaSumi)
                                .frame(width: 44, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.irohaWashi3)
                                        .frame(height: 4)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.irohaFuji)
                                        .frame(width: max(0, geo.size.width * CGFloat(ratio)), height: 4)
                                }
                                .frame(maxHeight: .infinity, alignment: .center)
                            }
                            .frame(height: 20)
                            Text(verbatim: "\(visitedInPeriod)/\(total)")
                                .font(.system(size: 11))
                                .monospacedDigit()
                                .foregroundColor(.irohaSumi3)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                    .tint(.irohaSumi3)
                    .padding(.vertical, 6)

                    if region != Region.allCases.last {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.irohaCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.irohaWashi3, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Travel distance

    private var travelDistanceSection: some View {
        let earthCircumference = 40_075.0
        let earthRatio = Double(totalDistance) / earthCircumference

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text("旅の距離")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.irohaSumi3)
                    .tracking(2)
                Button {
                    showDistanceInfo.toggle()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.irohaSumi3)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("旅の距離の説明")
                .popover(isPresented: $showDistanceInfo, arrowEdge: .bottom) {
                    Text("東京を基準とした各旅行先へのおおよその直線距離の合計です。実際の移動距離とは異なります。")
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi)
                        .padding(14)
                        .frame(width: 240)
                        .presentationCompactAdaptation(.popover)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.irohaWashi3, lineWidth: 6)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: min(earthRatio, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [.irohaFujiLt, .irohaFujiDk],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Image(systemName: "globe.asia.australia")
                            .font(.system(size: 20))
                            .foregroundColor(.irohaFuji)
                        Text(String(format: "%.0f%%", earthRatio * 100))
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.irohaFujiDk)
                    }
                }
                .padding(.leading, 6)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(totalDistance.formatted())
                                .font(.system(size: 24, weight: .light, design: .serif))
                                .foregroundColor(.irohaFujiDk)
                            Text("km")
                                .font(.system(size: 12))
                                .foregroundColor(.irohaSumi3)
                                .padding(.bottom, 2)
                        }
                        Text(verbatim: "赤道一周 40,075 km の\(String(format: "%.1f%%", earthRatio * 100))")
                            .font(.system(size: 11))
                            .foregroundColor(.irohaSumi3)
                    }

                    if let farthest = farthestPrefecture, farthestDistance > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.irohaFuji)
                            Text("最遠地")
                                .font(.system(size: 11))
                                .foregroundColor(.irohaSumi3)
                            Text(verbatim: "\(farthest.name) \(farthestDistance.formatted()) km")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.irohaSumi)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Visit progression chart

    private var chartPeriodSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                let isActive = chartPeriod == period
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        chartPeriod = period
                        resetChartScrollPosition(period: period, selectedYear: selectedYear)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                            .foregroundColor(isActive ? .irohaSumi : .irohaSumi3)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(isActive ? Color.irohaFuji : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
        }
    }

    private var chartMaxY: Int {
        let maxCount = chartData.map(\.count).max() ?? 0
        return max(maxCount + 2, 3)
    }

    private var chartSummaryValue: Int {
        let visibleRange = chartVisibleDateRange
        if chartMetric == .visitCount {
            return chartData
                .filter { $0.date >= visibleRange.start && $0.date <= visibleRange.end }
                .reduce(0) { $0 + $1.count }
        } else {
            return prefectureChartData
                .filter { $0.date <= visibleRange.end }
                .last?.count ?? 0
        }
    }

    private var chartDateRangeLabel: String {
        let calendar = Calendar.current
        let range = chartVisibleDateRange
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        switch chartPeriod {
        case .week:
            formatter.dateFormat = "yyyy年M月d日"
            let start = formatter.string(from: range.start)
            formatter.dateFormat = "d日"
            let end = formatter.string(from: range.end)
            return "\(start)〜\(end)"
        case .month:
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: range.start)
        case .year:
            let year = calendar.component(.year, from: range.start)
            return "\(year)年"
        case .all:
            formatter.dateFormat = "yyyy年M月"
            return "\(formatter.string(from: range.start))〜\(formatter.string(from: range.end))"
        }
    }

    private var visitProgressionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("旅行グラフ")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            visitProgressionCard
        }
    }

    private var visitProgressionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(chartMetric == .visitCount ? "旅行回数" : "旅行県数")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.irohaSumi3)
                    .tracking(2)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        chartMetric = chartMetric == .visitCount ? .prefectureCount : .visitCount
                    }
                } label: {
                    Image(systemName: chartMetric == .visitCount ? "chart.bar.fill" : "chart.xyaxis.line")
                        .font(.system(size: 14))
                        .foregroundColor(.irohaFuji)
                        .frame(width: 28, height: 28)
                        .background(Color.irohaWashi2)
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(chartMetric == .visitCount ? "旅行県数に切り替え" : "旅行回数に切り替え")
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)

            chartPeriodSelector
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(chartMetric == .visitCount ? "合計" : "累計")
                    .font(.system(size: 11))
                    .foregroundColor(.irohaSumi3)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: "\(chartSummaryValue)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.irohaSumi)
                    Text(chartMetric == .visitCount ? "回" : "県")
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi3)
                }
                Text(chartDateRangeLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.irohaSumi3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Group {
                if chartMetric == .visitCount {
                    visitCountChart
                } else {
                    prefectureCountChart
                }
            }
            .frame(height: 160)
            .padding(.leading, 14)
            .padding(.trailing, 24)
            .padding(.vertical, 6)
        }
        .background(Color.irohaCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.irohaWashi3, lineWidth: 0.5)
        )
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var chartXMarkValues: AxisMarkValues {
        switch chartPeriod {
        case .week:
            return .stride(by: .day, count: 1)
        case .month:
            return .stride(by: .day, count: 7)
        case .year:
            return .stride(by: .month, count: 1)
        case .all:
            return .stride(by: .month, count: 1)
        }
    }

    @ViewBuilder
    private var visitCountChart: some View {
        let data = chartData
        let barUnit: Calendar.Component = (chartPeriod == .year || chartPeriod == .all) ? .month : .day
        let chart = Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("日付", point.date, unit: barUnit),
                    y: .value("回数", point.count)
                )
                .foregroundStyle(Color.irohaFuji)
                .cornerRadius(2)
            }

        }
        .chartYScale(domain: 0...chartMaxY)
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.irohaSumi3.opacity(0.1))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.irohaSumi3)
            }
        }
        .chartXAxis {
            AxisMarks(values: chartXMarkValues) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(chartXLabel(for: date))
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(Color.irohaSumi3)
            }
        }

        let range = chartDateRange
        chart
            .chartXScale(domain: range.start...chartExtendedEnd(for: range.end))
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: chartVisibleDomainLength)
            .chartScrollPosition(x: $chartScrollPosition)
    }

    @ViewBuilder
    private var prefectureCountChart: some View {
        let data = prefectureChartData
        let chart = Chart(data) { point in
            LineMark(
                x: .value("日付", point.date),
                y: .value("県数", point.count)
            )
            .foregroundStyle(Color.irohaFuji)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("日付", point.date),
                y: .value("県数", point.count)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.irohaFujiLt.opacity(0.3), Color.irohaFujiLt.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartYScale(domain: 0...prefectureChartMaxY)
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.irohaSumi3.opacity(0.1))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color.irohaSumi3)
            }
        }
        .chartXAxis {
            AxisMarks(values: chartXMarkValues) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(chartXLabel(for: date))
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(Color.irohaSumi3)
            }
        }

        let range = chartDateRange
        chart
            .chartXScale(domain: range.start...chartExtendedEnd(for: range.end))
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: chartVisibleDomainLength)
            .chartScrollPosition(x: $chartScrollPosition)
    }

    private func chartXLabel(for date: Date) -> String {
        let calendar = Calendar.current
        switch chartPeriod {
        case .week:
            let weekday = calendar.component(.weekday, from: date)
            return ["日", "月", "火", "水", "木", "金", "土"][weekday - 1]
        case .month:
            let day = calendar.component(.day, from: date)
            return "\(day)"
        case .year, .all:
            let month = calendar.component(.month, from: date)
            return "\(month)月"
        }
    }

}

// MARK: - Border helper

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.reduce(into: Path()) { path, edge in
            switch edge {
            case .top:    path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: width))
            case .bottom: path.addRect(CGRect(x: 0, y: rect.height - width, width: rect.width, height: width))
            case .leading:  path.addRect(CGRect(x: 0, y: 0, width: width, height: rect.height))
            case .trailing: path.addRect(CGRect(x: rect.width - width, y: 0, width: width, height: rect.height))
            }
        }
    }
}

// MARK: - ChartPeriod

private enum ChartPeriod: String, CaseIterable {
    case week = "週"
    case month = "月"
    case year = "年"
    case all  = "すべて"
}

// MARK: - ChartMetric

private enum ChartMetric {
    case visitCount
    case prefectureCount
}

// MARK: - JourneyDataPoint

private struct JourneyDataPoint: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

// MARK: - Preview

#Preview {
    JourneyTrackerView()
        .modelContainer(for: [Visit.self], inMemory: true)
}
