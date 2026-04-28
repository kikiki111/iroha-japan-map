//
//  MemoryNotificationManager.swift
//  Iroha
//
//  「今日の記憶」通知：過去の同じ月日に訪問した記録があれば通知する

import UserNotifications
import SwiftData

enum MemoryNotificationManager {

    private static let categoryID = "iroha_memory"

    // MARK: - Permission

    /// 通知許可をリクエスト
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Schedule

    /// 全 Visit を走査し、今日の記憶通知を1年分スケジュールする
    static func reschedule(visits: [Visit]) {
        let center = UNUserNotificationCenter.current()
        // 既存の「今日の記憶」通知をすべて削除
        center.getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("memory_") }.map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)

            // 設定がOFFなら再スケジュールしない
            let enabled = UserDefaults.standard.object(forKey: "notify_memory") as? Bool ?? true
            guard enabled else { return }

            scheduleNotifications(visits: visits, center: center)
        }
    }

    private static func scheduleNotifications(visits: [Visit], center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        let today = Date()

        // 月日 → 訪問リスト のマップを作成
        var visitsByMonthDay: [String: [(visit: Visit, yearsAgo: Int)]] = [:]

        for visit in visits {
            let visitYear = calendar.component(.year, from: visit.startDate)
            let currentYear = calendar.component(.year, from: today)
            let yearsAgo = currentYear - visitYear

            // 今年の訪問は対象外（1年以上前のみ）
            guard yearsAgo >= 1 else { continue }

            let month = calendar.component(.month, from: visit.startDate)
            let day = calendar.component(.day, from: visit.startDate)
            let key = "\(month)-\(day)"

            visitsByMonthDay[key, default: []].append((visit: visit, yearsAgo: yearsAgo))
        }

        // 各月日について、最も印象的な1件を通知としてスケジュール
        var scheduledCount = 0
        for (_, entries) in visitsByMonthDay {
            guard scheduledCount < 60 else { break } // iOS上限64件に余裕を持たせる

            // 最も古い訪問を優先（年数が大きい方が「◯年前の今日」のインパクトが大きい）
            guard let entry = entries.max(by: { $0.yearsAgo < $1.yearsAgo }) else { continue }

            let visit = entry.visit
            let yearsAgo = entry.yearsAgo

            let month = calendar.component(.month, from: visit.startDate)
            let day = calendar.component(.day, from: visit.startDate)

            let content = UNMutableNotificationContent()
            content.title = "今日の記憶"
            content.body = "\(yearsAgo)年前の今日、\(visit.prefectureName)を訪れました"
            content.sound = .default
            content.categoryIdentifier = categoryID

            var dateComponents = DateComponents()
            dateComponents.month = month
            dateComponents.day = day
            dateComponents.hour = 9 // 朝9時に通知

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let id = "memory_\(month)_\(day)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            center.add(request)
            scheduledCount += 1
        }
    }
}
