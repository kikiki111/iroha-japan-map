//
//  OnboardingView.swift
//  Iroha
//
//  初回起動時のオンボーディング（3画面）

import SwiftUI

/// 3画面オンボーディング
struct OnboardingView: View {
    @AppStorage("onboarding_done") private var onboardingDone = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.irohaFuji5, Color.irohaFujiDk, Color.irohaFuji],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Illustration area
                illustrationView
                    .frame(height: 160)
                    .padding(.horizontal, 32)

                Spacer()

                // Body content
                VStack(spacing: 0) {
                    // Step indicator
                    Text(String(format: "%02d / 03", currentPage + 1))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer().frame(height: 12)

                    // Title
                    Text(pageTitle)
                        .font(.system(size: 28, weight: .ultraLight, design: .serif))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer().frame(height: 14)

                    // Description
                    Text(pageDescription)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.72))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer().frame(height: 20)

                    // Page dots
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            if i == currentPage {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white)
                                    .frame(width: 18, height: 6)
                            } else {
                                Circle()
                                    .fill(.white.opacity(0.25))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                // Button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentPage < 2 {
                            currentPage += 1
                        } else {
                            onboardingDone = true
                        }
                    }
                } label: {
                    Text(currentPage < 2 ? "次へ" : "はじめる")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.36), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)

                // Skip button (hidden on last page)
                if currentPage < 2 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onboardingDone = true
                        }
                    } label: {
                        Text("スキップ")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 16)
                } else {
                    Spacer().frame(height: 40)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }

    // MARK: - Page content

    private var pageTitle: String {
        switch currentPage {
        case 0:  return "いろは歌は47文字"
        case 1:  return "タップで記録\n長押しで行きたい"
        default: return "旅の記録が\n自動でまとまる"
        }
    }

    private var pageDescription: String {
        switch currentPage {
        case 0:  return "日本は47都道府県。\nすべての旅を、地図に刻もう。"
        case 1:  return "日時とひとことメモを残すだけ。\n写真も添えられます。"
        default: return "3日以内の連続訪問は\nひとつの旅として表示されます。"
        }
    }

    // MARK: - Illustrations

    @ViewBuilder
    private var illustrationView: some View {
        switch currentPage {
        case 0:
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                VStack(spacing: 10) {
                    HStack(spacing: 14) {
                        Ellipse()
                            .fill(.white.opacity(0.22))
                            .frame(width: 60, height: 28)
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.white.opacity(0.2))
                            .frame(width: 50, height: 52)
                            .rotationEffect(.degrees(-8))
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.white.opacity(0.24))
                            .frame(width: 36, height: 34)
                            .rotationEffect(.degrees(-5))
                        Spacer()
                    }
                }
                .padding(20)
            }

        case 1:
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                VStack(spacing: 14) {
                    Circle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.7), lineWidth: 1.6)
                                .frame(width: 44, height: 44)
                        )
                }
            }

        default:
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 1.5)
                        .padding(.leading, 24)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.18 - Double(i) * 0.04))
                                .frame(height: 26)
                        }
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 24)
                }
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
