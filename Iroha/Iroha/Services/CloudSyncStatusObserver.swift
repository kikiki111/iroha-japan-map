//
//  CloudSyncStatusObserver.swift
//  Iroha
//

import Foundation
import CloudKit
import Network
import SwiftUI

/// iCloud 同期の状態を集約・公開するオブザーバ。
///
/// iOS 18 の SwiftData は CloudKit イベントを直接公開しないため、
/// 以下の組み合わせから推定的に状態を出す:
/// - `CKAccountStatus`: Apple ID サインイン状態
/// - `NWPathMonitor`: ネット接続状態
/// - `UserDefaults`: ユーザの同期 ON/OFF 設定、最終同期時刻
///
/// `CloudKit` 切替 (Phase 6) 後、`recordSyncCompleted()` を SwiftData の
/// `ModelContext.didSave` 通知から呼び出して最終同期時刻を更新する。
@MainActor
@Observable
final class CloudSyncStatusObserver {

    /// UserDefaults キー: ユーザが iCloud 同期を有効化しているか
    static let syncEnabledKey = "cloud_sync_enabled"

    /// CloudKit エンタイトルメントが設定済みか。
    /// Phase 6 完了 (Apple Developer Capabilities + Xcode Capabilities 設定済み) で `true`。
    static let cloudKitAvailable: Bool = true

    /// 推定同期状態
    enum SyncState {
        case disabled              // ユーザが OFF にしている
        case notSignedIn           // Apple ID 未サインイン
        case offline               // ネット未接続
        case ready                 // 同期可能 (待機中)
        case error(String)         // CloudKit エラー
    }

    private(set) var accountStatus: CKAccountStatus = .couldNotDetermine
    private(set) var isOnline: Bool = true

    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "iroha.cloud.path-monitor")

    init() {
        startMonitoring()
        Task { await refreshAccountStatus() }
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - Public API

    var syncEnabled: Bool {
        // UserDefaults 未設定時は default true (Apple ID サインイン中なら自動同期、Apple 純正アプリ型)
        get { (UserDefaults.standard.object(forKey: Self.syncEnabledKey) as? Bool) ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.syncEnabledKey) }
    }

    var state: SyncState {
        if !syncEnabled { return .disabled }
        if accountStatus == .noAccount || accountStatus == .restricted {
            return .notSignedIn
        }
        if !isOnline { return .offline }
        return .ready
    }

    /// アカウント状態を再取得 (アプリがフォアグラウンド復帰時など)
    func refreshAccountStatus() async {
        // CloudKit エンタイトルメント未設定で CKContainer.default() を呼ぶと
        // EXC_BREAKPOINT で落ちる。Phase 6 (Apple Developer Capabilities 設定後) に
        // cloudKitAvailable を true に切り替えてから有効化する。
        guard Self.cloudKitAvailable else { return }
        do {
            let status = try await CKContainer.default().accountStatus()
            await MainActor.run {
                self.accountStatus = status
            }
        } catch {
            // 取得失敗 → couldNotDetermine のまま
        }
    }

    // MARK: - Private

    private func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let connected = (path.status == .satisfied)
            Task { @MainActor [weak self] in
                self?.isOnline = connected
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }
}

// MARK: - Display helpers

extension CloudSyncStatusObserver.SyncState {
    var displayLabel: String {
        switch self {
        case .disabled:    return "オフ"
        case .notSignedIn: return "Apple ID にサインインしてください"
        case .offline:     return "オフライン"
        case .ready:       return "同期中"
        case .error(let msg): return "エラー: \(msg)"
        }
    }

    var displayColor: Color {
        switch self {
        case .disabled:    return .irohaSumi3
        case .notSignedIn, .offline, .error: return Color(hex: "#E05555")
        case .ready:       return Color(hex: "#5A8F7B")
        }
    }

    var iconName: String {
        switch self {
        case .disabled:    return "icloud.slash"
        case .notSignedIn: return "person.crop.circle.badge.exclamationmark"
        case .offline:     return "wifi.slash"
        case .ready:       return "checkmark.icloud"
        case .error:       return "exclamationmark.icloud"
        }
    }
}
