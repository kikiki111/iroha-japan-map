//
//  Badge.swift
//  Iroha
//

import SwiftUI

// MARK: - TravelerTier

enum TravelerTier: Int, CaseIterable, Identifiable {
    case beginner     = 0
    case intermediate = 1
    case advanced     = 2
    case master       = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .beginner:     return "初心者"
        case .intermediate: return "中級者"
        case .advanced:     return "上級者"
        case .master:       return "達人"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner:     return "旅立ちの章"
        case .intermediate: return "修練の章"
        case .advanced:     return "極めの章"
        case .master:       return "悟りの章"
        }
    }

    var tierColor: Color {
        switch self {
        case .beginner:     return Color(hex: "#B8A9D4")
        case .intermediate: return Color(hex: "#7B6BAD")
        case .advanced:     return Color(hex: "#4B3D7A")
        case .master:       return Color(hex: "#C4972A")
        }
    }

    var thresholdFromPrevious: Int {
        switch self {
        case .beginner:     return 0
        case .intermediate: return 8
        case .advanced:     return 8
        case .master:       return 10
        }
    }

    func isUnlocked(visits: [Visit], stats: VisitStats) -> Bool {
        guard self != .beginner else { return true }
        let prev = TravelerTier(rawValue: rawValue - 1)!
        let prevBadges = Badge.badges(for: prev)
        let earned = prevBadges.filter { $0.isEarned(visits: visits, stats: stats) }.count
        return earned >= thresholdFromPrevious
    }

    static func currentTier(visits: [Visit], stats: VisitStats) -> TravelerTier {
        var tier = TravelerTier.beginner
        for t in allCases where t != .beginner {
            if t.isUnlocked(visits: visits, stats: stats) {
                tier = t
            }
        }
        return tier
    }
}

// MARK: - BadgeCategory

enum BadgeCategory: String, CaseIterable {
    case road  = "旅の道"
    case skill = "旅の技"
    case proof = "旅の証"
}

// MARK: - Badge

enum Badge: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    // --- Tier 1: 初心者 ---
    case firstVisit, tenVisits, fiftyVisits, nationalConquest
    case regionConquest, fourSeasons, threeStyles, landlocked
    case firstPhoto, hundredPhotos, sixMoods, prolificWriter

    // --- Tier 2: 中級者 ---
    case thirtyVisits, hundredVisits, twentyPrefectures, multiPrefTrip
    case threeRegions, samePrefFourSeasons, fiveTransports, soloAndGroup
    case tenPhotoPrefectures, threeHundredPhotos, moodGeography, thirtyNotes

    // --- Tier 3: 上級者 ---
    case twoHundredVisits, thirtyFivePrefectures, repeatVisitor, longJourney
    case fiveRegions, nightOwl, allTransports, islandHopper
    case twentyPhotoPrefectures, fiveHundredPhotos, locationLogger, companionCollector

    // --- Tier 4: 達人 ---
    case fiveHundredVisits, allFortySevenAgain, thousandDays, grandTour
    case allRegionsConquest, yearRoundTraveler, slowTraveler, namedTrips
    case allPrefecturePhotos, thousandPhotos, moodMaster, hundredNotes

    // MARK: - Tier

    var tier: TravelerTier {
        switch self {
        case .firstVisit, .tenVisits, .fiftyVisits, .nationalConquest,
             .regionConquest, .fourSeasons, .threeStyles, .landlocked,
             .firstPhoto, .hundredPhotos, .sixMoods, .prolificWriter:
            return .beginner
        case .thirtyVisits, .hundredVisits, .twentyPrefectures, .multiPrefTrip,
             .threeRegions, .samePrefFourSeasons, .fiveTransports, .soloAndGroup,
             .tenPhotoPrefectures, .threeHundredPhotos, .moodGeography, .thirtyNotes:
            return .intermediate
        case .twoHundredVisits, .thirtyFivePrefectures, .repeatVisitor, .longJourney,
             .fiveRegions, .nightOwl, .allTransports, .islandHopper,
             .twentyPhotoPrefectures, .fiveHundredPhotos, .locationLogger, .companionCollector:
            return .advanced
        case .fiveHundredVisits, .allFortySevenAgain, .thousandDays, .grandTour,
             .allRegionsConquest, .yearRoundTraveler, .slowTraveler, .namedTrips,
             .allPrefecturePhotos, .thousandPhotos, .moodMaster, .hundredNotes:
            return .master
        }
    }

    // MARK: - Category

    var category: BadgeCategory {
        switch self {
        case .firstVisit, .tenVisits, .fiftyVisits, .nationalConquest,
             .thirtyVisits, .hundredVisits, .twentyPrefectures, .multiPrefTrip,
             .twoHundredVisits, .thirtyFivePrefectures, .repeatVisitor, .longJourney,
             .fiveHundredVisits, .allFortySevenAgain, .thousandDays, .grandTour:
            return .road
        case .regionConquest, .fourSeasons, .threeStyles, .landlocked,
             .threeRegions, .samePrefFourSeasons, .fiveTransports, .soloAndGroup,
             .fiveRegions, .nightOwl, .allTransports, .islandHopper,
             .allRegionsConquest, .yearRoundTraveler, .slowTraveler, .namedTrips:
            return .skill
        case .firstPhoto, .hundredPhotos, .sixMoods, .prolificWriter,
             .tenPhotoPrefectures, .threeHundredPhotos, .moodGeography, .thirtyNotes,
             .twentyPhotoPrefectures, .fiveHundredPhotos, .locationLogger, .companionCollector,
             .allPrefecturePhotos, .thousandPhotos, .moodMaster, .hundredNotes:
            return .proof
        }
    }

    // MARK: - Stamp Character

    var stampCharacter: String {
        switch self {
        // Tier 1
        case .firstVisit:       return "初"
        case .tenVisits:        return "十"
        case .fiftyVisits:      return "達"
        case .nationalConquest: return "覇"
        case .regionConquest:   return "制"
        case .fourSeasons:      return "季"
        case .threeStyles:      return "路"
        case .landlocked:       return "山"
        case .firstPhoto:       return "景"
        case .hundredPhotos:    return "百"
        case .sixMoods:         return "心"
        case .prolificWriter:   return "筆"
        // Tier 2
        case .thirtyVisits:         return "参"
        case .hundredVisits:        return "壱"
        case .twentyPrefectures:    return "廿"
        case .multiPrefTrip:        return "連"
        case .threeRegions:         return "域"
        case .samePrefFourSeasons:  return "彩"
        case .fiveTransports:       return "乗"
        case .soloAndGroup:         return "友"
        case .tenPhotoPrefectures:  return "写"
        case .threeHundredPhotos:   return "撮"
        case .moodGeography:        return "想"
        case .thirtyNotes:          return "記"
        // Tier 3
        case .twoHundredVisits:       return "双"
        case .thirtyFivePrefectures:  return "拾"
        case .repeatVisitor:          return "馴"
        case .longJourney:            return "遠"
        case .fiveRegions:            return "踏"
        case .nightOwl:               return "宵"
        case .allTransports:          return "駆"
        case .islandHopper:           return "渡"
        case .twentyPhotoPrefectures: return "映"
        case .fiveHundredPhotos:      return "眼"
        case .locationLogger:         return "地"
        case .companionCollector:     return "縁"
        // Tier 4
        case .fiveHundredVisits:    return "極"
        case .allFortySevenAgain:   return "環"
        case .thousandDays:         return "歳"
        case .grandTour:            return "巡"
        case .allRegionsConquest:   return "統"
        case .yearRoundTraveler:    return "暦"
        case .slowTraveler:         return "歩"
        case .namedTrips:           return "銘"
        case .allPrefecturePhotos:  return "錦"
        case .thousandPhotos:       return "宝"
        case .moodMaster:           return "悟"
        case .hundredNotes:         return "文"
        }
    }

    // MARK: - Display Name

    var displayName: String {
        switch self {
        // Tier 1
        case .firstVisit:       return "初旅"
        case .tenVisits:        return "十の旅路"
        case .fiftyVisits:      return "旅の達人"
        case .nationalConquest: return "全国制覇"
        case .regionConquest:   return "地方制覇"
        case .fourSeasons:      return "四季巡り"
        case .threeStyles:      return "三つの旅路"
        case .landlocked:       return "海なし八県"
        case .firstPhoto:       return "一景"
        case .hundredPhotos:    return "百景"
        case .sixMoods:         return "六色の心"
        case .prolificWriter:   return "筆まめ"
        // Tier 2
        case .thirtyVisits:         return "三十路の旅"
        case .hundredVisits:        return "百旅"
        case .twentyPrefectures:    return "二十国巡り"
        case .multiPrefTrip:        return "連なる旅路"
        case .threeRegions:         return "三域踏破"
        case .samePrefFourSeasons:  return "四季一国"
        case .fiveTransports:       return "五つの乗物"
        case .soloAndGroup:         return "一人と仲間"
        case .tenPhotoPrefectures:  return "十国写景"
        case .threeHundredPhotos:   return "三百景"
        case .moodGeography:        return "心の旅地図"
        case .thirtyNotes:          return "三十の記"
        // Tier 3
        case .twoHundredVisits:       return "双百の旅"
        case .thirtyFivePrefectures:  return "三十五国"
        case .repeatVisitor:          return "馴染みの土地"
        case .longJourney:            return "遠き旅路"
        case .fiveRegions:            return "五域踏破"
        case .nightOwl:               return "宵の旅人"
        case .allTransports:          return "八つの足"
        case .islandHopper:           return "島渡り"
        case .twentyPhotoPrefectures: return "二十国映景"
        case .fiveHundredPhotos:      return "五百の眼"
        case .locationLogger:         return "地の記録者"
        case .companionCollector:     return "縁の旅人"
        // Tier 4
        case .fiveHundredVisits:    return "旅の極み"
        case .allFortySevenAgain:   return "全国再訪"
        case .thousandDays:         return "千日の旅人"
        case .grandTour:            return "大巡行"
        case .allRegionsConquest:   return "八域統一"
        case .yearRoundTraveler:    return "十二月の旅人"
        case .slowTraveler:         return "歩みの旅"
        case .namedTrips:           return "銘旅十選"
        case .allPrefecturePhotos:  return "四十七錦景"
        case .thousandPhotos:       return "千の宝景"
        case .moodMaster:           return "心の達人"
        case .hundredNotes:         return "百文の旅記"
        }
    }

    // MARK: - Description

    var description: String {
        switch self {
        // Tier 1
        case .firstVisit:       return "旅の一歩を踏み出した証"
        case .tenVisits:        return "十の地を巡り、旅人となる"
        case .fiftyVisits:      return "五十の旅路を重ね、道を究む"
        case .nationalConquest: return "四十七の国、すべてを巡り終えた"
        case .regionConquest:   return "ひとつの地方の隅々まで足跡を残した"
        case .fourSeasons:      return "春夏秋冬、四季折々の風景を巡った"
        case .threeStyles:      return "三つ以上の旅のスタイルを経験した"
        case .landlocked:       return "海なき八つの国を踏破した"
        case .firstPhoto:       return "旅の一景を切り取った"
        case .hundredPhotos:    return "百の景色を手元に収めた"
        case .sixMoods:         return "六つの心模様をすべて味わった"
        case .prolificWriter:   return "十の旅に筆を執り、想いを綴った"
        // Tier 2
        case .thirtyVisits:         return "三十の道を歩み、旅の深みを知る"
        case .hundredVisits:        return "百たびの旅路、その足跡は大河のごとし"
        case .twentyPrefectures:    return "二十の国を越え、日本の広さを知る"
        case .multiPrefTrip:        return "一度の旅で三つ以上の国を巡った"
        case .threeRegions:         return "三つの地方を隅々まで巡り終えた"
        case .samePrefFourSeasons:  return "同じ国を春夏秋冬すべてに訪れた"
        case .fiveTransports:       return "五種の乗物で旅路を辿った"
        case .soloAndGroup:         return "一人旅と仲間との旅、ふたつの味を知る"
        case .tenPhotoPrefectures:  return "十の国で景色を切り取った"
        case .threeHundredPhotos:   return "三百の眼差しを旅に向けた"
        case .moodGeography:        return "三つ以上の国で異なる心模様を記した"
        case .thirtyNotes:          return "三十の旅に想いを綴り、記憶を紡ぐ"
        // Tier 3
        case .twoHundredVisits:       return "二百の旅路を重ね、道は自ずと開く"
        case .thirtyFivePrefectures:  return "三十五の国に足跡を刻んだ"
        case .repeatVisitor:          return "五つの国を三度以上訪れた常連"
        case .longJourney:            return "七日を超える長旅を果たした"
        case .fiveRegions:            return "五つの地方を余すことなく巡り終えた"
        case .nightOwl:               return "十の宿に泊まり、夜の風情を知る"
        case .allTransports:          return "八種すべての乗物で日本を駆けた"
        case .islandHopper:           return "北海道・四国・九州・沖縄に足跡を残した"
        case .twentyPhotoPrefectures: return "二十の国で風景を映し出した"
        case .fiveHundredPhotos:      return "五百の景色を慈しみの眼で捉えた"
        case .locationLogger:         return "三十の旅行に場所の名を記した"
        case .companionCollector:     return "五人以上の仲間と旅をした"
        // Tier 4
        case .fiveHundredVisits:    return "五百の旅路、もはや道そのものとなった"
        case .allFortySevenAgain:   return "四十七すべての国を二度以上訪れた"
        case .thousandDays:         return "旅の記録が千日を超え、歳月が道となる"
        case .grandTour:            return "一度の旅で五つ以上の国を巡る壮大な旅路"
        case .allRegionsConquest:   return "八つの地方すべてを制し、日本を統べた"
        case .yearRoundTraveler:    return "一年の十二月すべてに旅をした"
        case .slowTraveler:         return "自転車か徒歩で五つ以上の国を訪れた"
        case .namedTrips:           return "十の旅に名を付け、物語を刻んだ"
        case .allPrefecturePhotos:  return "四十七の国すべてで景色を切り取った"
        case .thousandPhotos:       return "千の景色を手元に収めた旅の証"
        case .moodMaster:           return "六つの心模様をそれぞれ十回以上味わった"
        case .hundredNotes:         return "百の旅に筆を執り、旅の文豪となった"
        }
    }

    // MARK: - Stamp Color

    var stampColor: Color {
        switch self {
        // Tier 1
        case .firstVisit:       return Color(hex: "#B8A9D4")
        case .tenVisits:        return Color(hex: "#8672B5")
        case .fiftyVisits:      return Color(hex: "#65519B")
        case .nationalConquest: return Color(hex: "#C4972A")
        case .regionConquest:   return Color(hex: "#5A8F7B")
        case .fourSeasons:      return Color(hex: "#D4736A")
        case .threeStyles:      return Color(hex: "#B88B4A")
        case .landlocked:       return Color(hex: "#5B7A3E")
        case .firstPhoto:       return Color(hex: "#D4956A")
        case .hundredPhotos:    return Color(hex: "#C53D43")
        case .sixMoods:         return Color(hex: "#9B6B9A")
        case .prolificWriter:   return Color(hex: "#4A6B8A")
        // Tier 2
        case .thirtyVisits:         return Color(hex: "#7B6BAD")
        case .hundredVisits:        return Color(hex: "#5B4F8C")
        case .twentyPrefectures:    return Color(hex: "#8B7EC8")
        case .multiPrefTrip:        return Color(hex: "#D4A76A")
        case .threeRegions:         return Color(hex: "#4A7F6B")
        case .samePrefFourSeasons:  return Color(hex: "#C95B5B")
        case .fiveTransports:       return Color(hex: "#A07B3F")
        case .soloAndGroup:         return Color(hex: "#6B8E4E")
        case .tenPhotoPrefectures:  return Color(hex: "#C4856A")
        case .threeHundredPhotos:   return Color(hex: "#B53040")
        case .moodGeography:        return Color(hex: "#8B5B8A")
        case .thirtyNotes:          return Color(hex: "#3B5F7A")
        // Tier 3
        case .twoHundredVisits:       return Color(hex: "#6B5B9E")
        case .thirtyFivePrefectures:  return Color(hex: "#5A4B8E")
        case .repeatVisitor:          return Color(hex: "#9E8B6A")
        case .longJourney:            return Color(hex: "#B8956A")
        case .fiveRegions:            return Color(hex: "#3A6F5B")
        case .nightOwl:               return Color(hex: "#A04050")
        case .allTransports:          return Color(hex: "#8A6B30")
        case .islandHopper:           return Color(hex: "#4B7A3E")
        case .twentyPhotoPrefectures: return Color(hex: "#B06B4A")
        case .fiveHundredPhotos:      return Color(hex: "#9E2E3A")
        case .locationLogger:         return Color(hex: "#7A4B7A")
        case .companionCollector:     return Color(hex: "#2E5070")
        // Tier 4
        case .fiveHundredVisits:    return Color(hex: "#4B3D7A")
        case .allFortySevenAgain:   return Color(hex: "#3A2D6E")
        case .thousandDays:         return Color(hex: "#8E7B5A")
        case .grandTour:            return Color(hex: "#C4972A")
        case .allRegionsConquest:   return Color(hex: "#2A5F4B")
        case .yearRoundTraveler:    return Color(hex: "#8E3545")
        case .slowTraveler:         return Color(hex: "#7A5B25")
        case .namedTrips:           return Color(hex: "#3E6B3E")
        case .allPrefecturePhotos:  return Color(hex: "#9E5B40")
        case .thousandPhotos:       return Color(hex: "#7A1E2A")
        case .moodMaster:           return Color(hex: "#5E3D6E")
        case .hundredNotes:         return Color(hex: "#1E3F5A")
        }
    }

    // MARK: - Stamp Rotation

    var stampRotation: Double {
        switch self {
        // Tier 1
        case .firstVisit:       return -3
        case .tenVisits:        return 2
        case .fiftyVisits:      return -1
        case .nationalConquest: return 4
        case .regionConquest:   return -2
        case .fourSeasons:      return 3
        case .threeStyles:      return -4
        case .landlocked:       return 1
        case .firstPhoto:       return -3
        case .hundredPhotos:    return 2
        case .sixMoods:         return -1
        case .prolificWriter:   return 3
        // Tier 2
        case .thirtyVisits:         return -2
        case .hundredVisits:        return 3
        case .twentyPrefectures:    return -1
        case .multiPrefTrip:        return 4
        case .threeRegions:         return -3
        case .samePrefFourSeasons:  return 2
        case .fiveTransports:       return -4
        case .soloAndGroup:         return 1
        case .tenPhotoPrefectures:  return -2
        case .threeHundredPhotos:   return 3
        case .moodGeography:        return -1
        case .thirtyNotes:          return 2
        // Tier 3
        case .twoHundredVisits:       return 3
        case .thirtyFivePrefectures:  return -2
        case .repeatVisitor:          return 1
        case .longJourney:            return -4
        case .fiveRegions:            return -1
        case .nightOwl:               return 2
        case .allTransports:          return -3
        case .islandHopper:           return 4
        case .twentyPhotoPrefectures: return 2
        case .fiveHundredPhotos:      return -1
        case .locationLogger:         return 3
        case .companionCollector:     return -2
        // Tier 4
        case .fiveHundredVisits:    return -1
        case .allFortySevenAgain:   return 4
        case .thousandDays:         return -3
        case .grandTour:            return 2
        case .allRegionsConquest:   return -2
        case .yearRoundTraveler:    return 3
        case .slowTraveler:         return -4
        case .namedTrips:           return 1
        case .allPrefecturePhotos:  return 2
        case .thousandPhotos:       return -1
        case .moodMaster:           return 3
        case .hundredNotes:         return -2
        }
    }

    // MARK: - Queries

    static func badges(for category: BadgeCategory) -> [Badge] {
        allCases.filter { $0.category == category }
    }

    static func badges(for tier: TravelerTier) -> [Badge] {
        allCases.filter { $0.tier == tier }
    }

    static func badges(for tier: TravelerTier, category: BadgeCategory) -> [Badge] {
        allCases.filter { $0.tier == tier && $0.category == category }
    }

    // MARK: - isEarned

    private static let landlockedIDs: Set<Int> = [9, 10, 11, 19, 20, 21, 25, 29]

    /// 写真がある記録に登場した都道府県 ID 集合 (1 レコード複数県対応)。
    private static func prefectureIDsWithPhotos(_ visits: [Visit]) -> Set<Int> {
        Set(visits.filter(\.hasPhotos).flatMap(\.effectivePrefectureIDs))
    }

    func isEarned(visits: [Visit], stats: VisitStats) -> Bool {
        // 「旅の回数・日数」を数える実績からは居住記録を除外する。
        // 居住は期間が数年に及ぶため、含めると件数が水増しされ、
        // `nightOwl` (累計 10 泊) は居住 1 件で即達成してしまう。
        // 写真・メモ・ムード系は居住記録の分も実績に含めてよいので `visits` のまま。
        let travelVisits = visits.filter { !$0.isResidence }
        // 月が確定している旅行記録。四季 (`fourSeasons` / `samePrefFourSeasons`) と
        // 12 ヶ月 (`yearRoundTraveler`) の判定に使う。`.month` は代表日こそ月末だが
        // 月成分は正しいので対象に含め、`.year` (月不明) だけを落とす。
        let monthKnownVisits = travelVisits.filter { $0.effectiveDateAccuracy.hasMonth }
        // 日まで確定している旅行記録。日数差を測る `thousandDays` に使う。
        let dayKnownVisits = travelVisits.filter { !$0.isDateAmbiguous }

        switch self {

        // ── Tier 1: 初心者 ──

        case .firstVisit:
            return !travelVisits.isEmpty

        case .tenVisits:
            return travelVisits.count >= 10

        case .fiftyVisits:
            return travelVisits.count >= 50

        case .nationalConquest:
            return stats.visitedCount >= 47

        case .regionConquest:
            return Region.allCases.contains { stats.isRegionConquered($0) }

        case .fourSeasons:
            let calendar = Calendar.current
            let months = Set(monthKnownVisits.map { calendar.component(.month, from: $0.startDate) })
            let spring = months.contains(where: { (3...5).contains($0) })
            let summer = months.contains(where: { (6...8).contains($0) })
            let autumn = months.contains(where: { (9...11).contains($0) })
            let winter = months.contains(where: { $0 == 12 || $0 == 1 || $0 == 2 })
            return spring && summer && autumn && winter

        case .threeStyles:
            // ID ベースで数える。カタログを引かないのは判定を純粋関数に保つためで、
            // プリセットもユーザー定義も等しく 1 スタイルとして扱う。
            // 未選択は effectiveStyleID が nil を返すので compactMap で落ちる。
            let styleIDs = Set(visits.compactMap(\.effectiveStyleID))
                .subtracting(TravelStylePreset.legacyIDs)
            return styleIDs.count >= 3

        case .landlocked:
            return Self.landlockedIDs.isSubset(of: stats.visitedIDs)

        case .firstPhoto:
            return visits.contains(where: \.hasPhotos)

        case .hundredPhotos:
            return visits.reduce(0) { $0 + $1.totalPhotoCount } >= 100

        case .sixMoods:
            let moods = Set(visits.map(\.effectiveMood))
            return VisitMood.selectable.allSatisfy { moods.contains($0) }

        case .prolificWriter:
            return visits.filter { !$0.note.isEmpty }.count >= 10

        // ── Tier 2: 中級者 ──

        case .thirtyVisits:
            return travelVisits.count >= 30

        case .hundredVisits:
            return travelVisits.count >= 100

        case .twentyPrefectures:
            return stats.visitedCount >= 20

        case .multiPrefTrip:
            let trips = TripDetector.detect(from: visits)
            return trips.contains { $0.prefectureNames.count >= 3 }

        case .threeRegions:
            return Region.allCases.filter { stats.isRegionConquered($0) }.count >= 3

        case .samePrefFourSeasons:
            let calendar = Calendar.current
            let grouped = VisitStats.groupedByPrefectureID(monthKnownVisits)
            return grouped.values.contains { prefVisits in
                let months = Set(prefVisits.map { calendar.component(.month, from: $0.startDate) })
                let spring = months.contains(where: { (3...5).contains($0) })
                let summer = months.contains(where: { (6...8).contains($0) })
                let autumn = months.contains(where: { (9...11).contains($0) })
                let winter = months.contains(where: { $0 == 12 || $0 == 1 || $0 == 2 })
                return spring && summer && autumn && winter
            }

        case .fiveTransports:
            let all = Set(visits.flatMap(\.effectiveTransports))
            return all.count >= 5

        case .soloAndGroup:
            return visits.contains(where: \.hasCompanions) && visits.contains(where: { !$0.hasCompanions })

        case .tenPhotoPrefectures:
            return Self.prefectureIDsWithPhotos(visits).count >= 10

        case .threeHundredPhotos:
            return visits.reduce(0) { $0 + $1.totalPhotoCount } >= 300

        case .moodGeography:
            let grouped = VisitStats.groupedByPrefectureID(visits)
            let qualifying = grouped.values.filter { prefVisits in
                Set(prefVisits.map(\.effectiveMood).filter { $0 != .none }).count >= 2
            }
            return qualifying.count >= 3

        case .thirtyNotes:
            return visits.filter { !$0.note.isEmpty }.count >= 30

        // ── Tier 3: 上級者 ──

        case .twoHundredVisits:
            return travelVisits.count >= 200

        case .thirtyFivePrefectures:
            return stats.visitedCount >= 35

        case .repeatVisitor:
            let grouped = VisitStats.groupedByPrefectureID(travelVisits)
            let repeats = grouped.values.filter { $0.count >= 3 }
            return repeats.count >= 5

        case .longJourney:
            // 日付が曖昧な旅は nightCount が nil になり、対象から外れる
            // (例: 年月精度の「5月〜6月」は代表日の差が 30 日あるが実際の泊数は不明)
            let trips = TripDetector.detect(from: visits)
            return trips.contains { ($0.nightCount ?? 0) >= 7 }

        case .fiveRegions:
            return Region.allCases.filter { stats.isRegionConquered($0) }.count >= 5

        case .nightOwl:
            // `nightCount` は居住と日付が曖昧な記録で nil を返すため、compactMap で自然に落ちる。
            // (居住を含めると 1 件・数年で即達成してしまう)
            let totalNights = travelVisits
                .compactMap(\.nightCount)
                .filter { $0 > 0 }
                .reduce(0, +)
            return totalNights >= 10

        case .allTransports:
            let all = Set(visits.flatMap(\.effectiveTransports))
            return VisitTransport.selectable.allSatisfy { all.contains($0) }

        case .islandHopper:
            let hasHokkaido = stats.visitedPrefectures.contains { $0.region == .hokkaido }
            let hasShikoku = stats.visitedPrefectures.contains { $0.region == .shikoku }
            let hasKyushu = stats.visitedPrefectures.contains { $0.region == .kyushu }
            let hasOkinawa = stats.visitedIDs.contains(47)
            return hasHokkaido && hasShikoku && hasKyushu && hasOkinawa

        case .twentyPhotoPrefectures:
            return Self.prefectureIDsWithPhotos(visits).count >= 20

        case .fiveHundredPhotos:
            return visits.reduce(0) { $0 + $1.totalPhotoCount } >= 500

        case .locationLogger:
            return visits.filter(\.hasLocation).count >= 30

        case .companionCollector:
            let allCompanions = Set(visits.flatMap(\.companions))
            return allCompanions.count >= 5

        // ── Tier 4: 達人 ──

        case .fiveHundredVisits:
            return travelVisits.count >= 500

        case .allFortySevenAgain:
            return Prefecture.all.allSatisfy { stats.count(for: $0) >= 2 }

        case .thousandDays:
            // 日単位の差を測るので、代表日に丸められた曖昧な記録は除外する
            guard let earliest = dayKnownVisits.map(\.startDate).min(),
                  let latest = dayKnownVisits.map(\.startDate).max() else { return false }
            let days = Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0
            return days >= 1000

        case .grandTour:
            let trips = TripDetector.detect(from: visits)
            return trips.contains { $0.prefectureNames.count >= 5 }

        case .allRegionsConquest:
            return Region.allCases.allSatisfy { stats.isRegionConquered($0) }

        case .yearRoundTraveler:
            let calendar = Calendar.current
            let months = Set(monthKnownVisits.map { calendar.component(.month, from: $0.startDate) })
            return months.count >= 12

        case .slowTraveler:
            let slowPrefs = Set(visits.filter { visit in
                visit.effectiveTransports.contains(.bicycle) || visit.effectiveTransports.contains(.walking)
            }.flatMap(\.effectivePrefectureIDs))
            return slowPrefs.count >= 5

        case .namedTrips:
            return visits.filter { !$0.tripName.isEmpty }.count >= 10

        case .allPrefecturePhotos:
            return Self.prefectureIDsWithPhotos(visits).count >= 47

        case .thousandPhotos:
            return visits.reduce(0) { $0 + $1.totalPhotoCount } >= 1000

        case .moodMaster:
            let moodCounts = Dictionary(grouping: visits.map(\.effectiveMood).filter { $0 != .none }, by: \.self)
                .mapValues(\.count)
            return VisitMood.selectable.allSatisfy { (moodCounts[$0] ?? 0) >= 10 }

        case .hundredNotes:
            return visits.filter { !$0.note.isEmpty }.count >= 100
        }
    }
}
