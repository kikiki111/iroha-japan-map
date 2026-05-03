//
//  TimelineView.swift
//  Iroha
//
//  旅日記タブ（タイムライン）

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
    @State private var selectedTrip: Trip?

    private var isAllYearsMode: Bool { selectedYear == -1 }

    private var availableYears: [Int] {
        let calendar = Calendar.current
        let years = Set(visits.map { calendar.component(.year, from: $0.startDate) })
        return years.sorted(by: >)
    }

    private var currentYear: Int {
        if selectedYear > 0 { return selectedYear }
        return availableYears.first ?? Calendar.current.component(.year, from: Date())
    }

    private var filteredVisits: [Visit] {
        if isAllYearsMode { return Array(visits) }
        let calendar = Calendar.current
        return visits.filter { calendar.component(.year, from: $0.startDate) == currentYear }
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
                    Text("旅の軌跡")
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
                VisitFormView(prefectures: prefectures, prefecture: nil, editingVisit: nil)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $editingVisit) { visit in
                VisitFormView(prefectures: prefectures, prefecture: nil, editingVisit: visit)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailSheet(trip: trip, prefectures: prefectures) { visit in
                    selectedTrip = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        editingVisit = visit
                    }
                }
                .environment(\.locale, Locale(identifier: "ja_JP"))
            }
        }
    }

    // MARK: - Timeline content

    private var timelineContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                MemoryCardView { visit in
                    let allTrips = TripDetector.detect(from: Array(visits))
                    if let trip = allTrips.first(where: { $0.visits.contains { $0.id == visit.id } }) {
                        selectedTrip = trip
                    }
                }
                yearSwitcher
                yearHeader
                monthlyTripCards
            }
        }
    }

    // MARK: - Year switcher

    private var yearSwitcher: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedYear = -1
                        }
                    } label: {
                        Text("すべて")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isAllYearsMode ? .white : .irohaSumi2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(isAllYearsMode ? Color.irohaFujiDk : Color.irohaWashi2)
                            .clipShape(Capsule())
                    }
                    .id(-1)

                    ForEach(availableYears, id: \.self) { year in
                        let isSelected = year == currentYear && !isAllYearsMode
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedYear = year
                            }
                        } label: {
                            Text(verbatim: "\(year)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isSelected ? .white : .irohaSumi2)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background(isSelected ? Color.irohaFujiDk : Color.irohaWashi2)
                                .clipShape(Capsule())
                        }
                        .id(year)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
        .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
    }

    // MARK: - Year header

    private var yearHeader: some View {
        let yearVisits = filteredVisits
        let prefCount = Set(yearVisits.map(\.prefectureName)).count
        let tripCount = TripDetector.detect(from: yearVisits).count

        return HStack(alignment: .bottom) {
            if isAllYearsMode {
                NurikakeText(text: "すべての旅", fontSize: 28, fillFromTop: true)
            } else {
                NurikakeText(text: "\(currentYear)", fontSize: 36, fillFromTop: true)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 3) {
                    Text(verbatim: "\(prefCount)県")
                        .font(.system(size: 14, weight: .bold))
                    Text("\u{00B7}")
                        .foregroundColor(.irohaSumi3)
                    Text(verbatim: "\(tripCount)旅")
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

    // MARK: - Timeline

    private var monthlyTripCards: some View {
        let calendar = Calendar.current
        let allTrips = TripDetector.detect(from: filteredVisits)
            .sorted { $0.startDate > $1.startDate }

        let items = buildTimelineItems(trips: allTrips, calendar: calendar)

        return VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                switch item {
                case .yearHeader(let year):
                    timelineYearHeader(year: year)
                case .monthHeader(let month):
                    timelineMonthHeader(month: month)
                case .trip(let trip, let isLast):
                    timelineTripRow(trip: trip, isLast: isLast)
                    let nextIsSectionHeader = index + 1 < items.count && items[index + 1].isSectionHeader
                    if !isLast && !nextIsSectionHeader {
                        Divider()
                            .padding(.leading, 42)
                    }
                }
            }
        }
    }

    private enum TimelineItem {
        case yearHeader(Int)
        case monthHeader(Int)
        case trip(Trip, isLast: Bool)

        var isSectionHeader: Bool {
            switch self {
            case .yearHeader, .monthHeader: return true
            case .trip: return false
            }
        }
    }

    private func buildTimelineItems(trips: [Trip], calendar: Calendar) -> [TimelineItem] {
        var items: [TimelineItem] = []
        var lastMonth: Int?
        var lastYear: Int?
        for (i, trip) in trips.enumerated() {
            let year = calendar.component(.year, from: trip.startDate)
            let month = calendar.component(.month, from: trip.startDate)

            if isAllYearsMode && year != lastYear {
                items.append(.yearHeader(year))
                lastYear = year
                lastMonth = nil
            }

            if month != lastMonth {
                items.append(.monthHeader(month))
                lastMonth = month
            }
            items.append(.trip(trip, isLast: i == trips.count - 1))
        }
        return items
    }

    private func timelineYearHeader(year: Int) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.irohaFuji.opacity(0.3))
                .frame(width: 2)
                .padding(.leading, 24)
            Spacer()
        }
        .frame(height: 40)
        .overlay(alignment: .leading) {
            NurikakeText(text: "\(year)", fontSize: 22, fillFromTop: true)
                .padding(.leading, 42)
        }
    }

    private func timelineMonthHeader(month: Int) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.irohaFuji.opacity(0.3))
                .frame(width: 2)
                .padding(.leading, 24)

            Rectangle()
                .fill(Color.irohaWashi3)
                .frame(height: 0.5)
                .padding(.leading, -1)
        }
        .frame(height: 28)
        .overlay(alignment: .leading) {
            Text(verbatim: "\(month)月")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.irohaSumi3)
                .tracking(1)
                .padding(.horizontal, 6)
                .background(Color.irohaWashi)
                .padding(.leading, 36)
        }
    }

    private func timelineTripRow(trip: Trip, isLast: Bool) -> some View {
        Button {
            selectedTrip = trip
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.irohaFuji.opacity(0.3))
                        .frame(width: 2, height: 14)
                    Circle()
                        .fill(Color.irohaFuji)
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(isLast ? Color.clear : Color.irohaFuji.opacity(0.3))
                        .frame(width: 2)
                }
                .frame(width: 10)

                tripRowContent(trip: trip)
                    .padding(.vertical, 10)

                Spacer(minLength: 0)
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .buttonStyle(.plain)
    }

    private func tripRowContent(trip: Trip) -> some View {
        let calendar = Calendar.current
        let allTransports = trip.visits.flatMap(\.effectiveTransports)
        let uniqueTransports = Array(Set(allTransports.map(\.rawValue)))
            .compactMap { VisitTransport(rawValue: $0) }
            .filter { $0 != .none }
        var globalIndex = 0
        let allThumbnails: [(Data, Int)] = trip.visits.flatMap { v in
            v.allPhotoThumbnails.map { thumb in
                defer { globalIndex += 1 }
                return (thumb, globalIndex)
            }
        }

        return VStack(alignment: .leading, spacing: 4) {
            // Row 1: Prefecture name(s) + badges
            if trip.isSingleVisit {
                let visit = trip.visits[0]
                HStack(spacing: 6) {
                    Text(visit.prefectureName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.irohaFujiDk)
                    if visit.effectiveTag != .none {
                        VisitTagBadge(tag: visit.effectiveTag)
                    }
                    if visit.effectiveMood != .none {
                        VisitMoodBadge(mood: visit.effectiveMood)
                    }
                }
            } else {
                let startDay = calendar.startOfDay(for: trip.startDate)
                let endDay = calendar.startOfDay(for: trip.endDate)
                let calendarNights = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0

                HStack(spacing: 6) {
                    Text(trip.prefectureNames.joined(separator: " → "))
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.irohaFujiDk)

                    Text(calendarNights > 0 ? "\(calendarNights)泊\(calendarNights + 1)日" : "日帰り")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.irohaSumi3)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.irohaWashi2)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Row 2: Transport icons + date (start, and return date if different)
            HStack(spacing: 5) {
                ForEach(uniqueTransports.prefix(3), id: \.rawValue) { t in
                    Image(systemName: t.iconName)
                        .font(.system(size: 11))
                        .foregroundColor(.irohaSumi3)
                }

                let isSameDay = calendar.isDate(trip.startDate, inSameDayAs: trip.endDate)
                if isSameDay {
                    Text(trip.startDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                        .font(.system(size: 12))
                        .foregroundColor(.irohaSumi3)
                } else {
                    HStack(spacing: 3) {
                        Text(trip.startDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                        Text("〜")
                        Text(trip.endDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.irohaSumi3)
                }
            }

            // Row 3: Location + trip name + memo (horizontal scroll on overflow)
            let primaryLocation = trip.visits.first(where: { $0.hasLocation })?.location
            let memo = trip.visits.first(where: { !$0.note.isEmpty })?.note
            if primaryLocation != nil || !trip.tripName.isEmpty || memo != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let loc = primaryLocation {
                            HStack(spacing: 2) {
                                Text("📍")
                                    .font(.system(size: 11))
                                Text(loc)
                                    .font(.system(size: 12))
                                    .foregroundColor(.irohaSumi2)
                                    .lineLimit(1)
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }
                        if !trip.tripName.isEmpty {
                            Text(trip.tripName)
                                .font(.system(size: 12))
                                .foregroundColor(.irohaSumi3)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        if let memo = memo {
                            Text(memo)
                                .font(.system(size: 12))
                                .foregroundColor(.irohaSumi2)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .scrollClipDisabled()
            }

            // Row 4: Photo thumbnails (horizontal scroll, all photos)
            if !allThumbnails.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 4) {
                        ForEach(allThumbnails, id: \.1) { data, _ in
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        ContentUnavailableView {
            Label("旅行記録がありません", systemImage: "map")
        } description: {
            Text("＋ボタンから旅した都道府県を追加しましょう。")
        }
    }

    // MARK: - Share

    private func shareYearRecap() {
        let visitedNames = Set(filteredVisits.map(\.prefectureName))
        ShareManager.shareMap(prefectures: prefectures, visitedNames: visitedNames, year: isAllYearsMode ? nil : currentYear)
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

// MARK: - TripDetailSheet

struct TripDetailSheet: View {
    let trip: Trip
    let prefectures: [Prefecture]
    var onEditVisit: ((Visit) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var fullscreenSelection: PhotoFullscreenSelection?

    private var nights: Int {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: trip.startDate)
        let endDay = calendar.startOfDay(for: trip.endDate)
        return calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
    }

    private var sortedVisits: [Visit] {
        trip.visits.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    tripHeader

                    // Timeline
                    VStack(spacing: 0) {
                        ForEach(Array(sortedVisits.enumerated()), id: \.element.id) { index, visit in
                            tripVisitRow(visit: visit, isFirst: index == 0, isLast: index == sortedVisits.count - 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("旅の詳細")
                        .font(.system(size: 20, weight: .light, design: .serif))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.irohaSumi3)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.ultraThinMaterial)
        .fullScreenCover(item: $fullscreenSelection) { selection in
            PhotoFullscreenViewer(
                filenames: selection.filenames,
                thumbnails: selection.thumbnails,
                initialIndex: selection.initialIndex
            )
        }
    }

    // MARK: - Header

    private var tripHeader: some View {
        VStack(spacing: 10) {
            if !trip.tripName.isEmpty {
                Text(trip.tripName)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.irohaFujiDk)
            }

            // Duration badge
            Text(nights > 0 ? "\(nights)泊\(nights + 1)日" : "日帰り")
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(.irohaFujiDk)

            // Date range
            HStack(spacing: 4) {
                Text(trip.startDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                if nights > 0 {
                    Text("〜")
                        .foregroundColor(.irohaSumi3)
                    Text(trip.endDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                }
            }
            .font(.system(size: 13))
            .foregroundColor(.irohaSumi2)

            // Route chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(trip.prefectureNames.enumerated()), id: \.offset) { i, name in
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.irohaFujiDk)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.irohaFujiLt.opacity(0.3))
                            .clipShape(Capsule())

                        if i < trip.prefectureNames.count - 1 {
                            Text("\u{2192}")
                                .font(.system(size: 12))
                                .foregroundColor(.irohaSumi3)
                        }
                    }
                }
            }

            // Stats
            HStack(spacing: 16) {
                statItem(value: "\(trip.prefectureNames.count)", label: "都道府県")
                statItem(value: "\(trip.visits.count)", label: "記録")
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.irohaFujiLt.opacity(0.15), Color.irohaFujiLt.opacity(0.03)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.irohaFujiDk)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.irohaSumi3)
        }
    }

    // MARK: - Visit row

    private func tripVisitRow(visit: Visit, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline line + dot
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.irohaFuji.opacity(0.3))
                    .frame(width: 2, height: 12)
                Circle()
                    .fill(Color.irohaFuji)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(isLast ? Color.clear : Color.irohaFuji.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Date
                Text(visit.startDate.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ja_JP"))))
                    .font(.system(size: 11))
                    .foregroundColor(.irohaSumi3)

                // Prefecture + tag + mood
                HStack(spacing: 6) {
                    Text(visit.prefectureName)
                        .font(.system(size: 16, weight: .bold))
                    if visit.effectiveTag != .none {
                        VisitTagBadge(tag: visit.effectiveTag)
                    }
                    if visit.effectiveMood != .none {
                        VisitMoodBadge(mood: visit.effectiveMood)
                    }
                    VisitTransportBadge(transports: visit.effectiveTransports)
                    VisitCompanionBadge(companions: visit.companions)
                }

                if visit.hasLocation || !trip.tripName.isEmpty {
                    HStack(spacing: 8) {
                        if visit.hasLocation {
                            HStack(spacing: 2) {
                                Text("📍")
                                    .font(.system(size: 11))
                                Text(visit.location)
                                    .font(.system(size: 12))
                                    .foregroundColor(.irohaSumi2)
                                    .lineLimit(1)
                            }
                        }
                        if !trip.tripName.isEmpty {
                            Text(trip.tripName)
                                .font(.system(size: 12))
                                .foregroundColor(.irohaSumi3)
                                .lineLimit(1)
                        }
                    }
                }

                // Photo thumbnails (Photos-app style 3-column grid)
                if !visit.allPhotoThumbnails.isEmpty {
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(Array(visit.allPhotoThumbnails.enumerated()), id: \.offset) { index, data in
                            if let uiImage = UIImage(data: data) {
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                    )
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        fullscreenSelection = PhotoFullscreenSelection(
                                            filenames: visit.allPhotoFilenames,
                                            thumbnails: visit.allPhotoThumbnails,
                                            initialIndex: index
                                        )
                                    }
                            }
                        }
                    }
                }

                // Memo
                if !visit.note.isEmpty {
                    Text(visit.note)
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi2)
                        .lineLimit(3)
                }

                // Edit button
                Button {
                    onEditVisit?(visit)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12))
                        Text("編集")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.irohaFujiDk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.irohaFujiLt.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.irohaFujiLt, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - PhotoFullscreenViewer

struct PhotoFullscreenSelection: Identifiable {
    let id = UUID()
    let filenames: [String]
    let thumbnails: [Data]
    let initialIndex: Int
}

struct PhotoFullscreenViewer: View {
    let filenames: [String]
    let thumbnails: [Data]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(filenames: [String], thumbnails: [Data], initialIndex: Int) {
        self.filenames = filenames
        self.thumbnails = thumbnails
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }

    private var pageCount: Int { max(filenames.count, thumbnails.count) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(0..<pageCount, id: \.self) { i in
                    photoView(at: i)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: pageCount > 1 ? .always : .never))
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.white, Color.black.opacity(0.45))
                    .padding(.trailing, 16)
                    .padding(.top, 12)
            }
        }
    }

    @ViewBuilder
    private func photoView(at index: Int) -> some View {
        if let image = loadImage(at: index) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Color.black
        }
    }

    private func loadImage(at index: Int) -> UIImage? {
        if index < filenames.count, let img = PhotoStorageManager.loadImage(filename: filenames[index]) {
            return img
        }
        if index < thumbnails.count, let img = UIImage(data: thumbnails[index]) {
            return img
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var vm = MapViewModel()
    TimelineView(mapViewModel: vm)
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
