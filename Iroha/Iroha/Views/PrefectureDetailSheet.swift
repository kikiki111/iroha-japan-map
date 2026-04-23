//
//  PrefectureDetailSheet.swift
//  Iroha
//
//  県詳細シート（タップで開く）

import SwiftUI
import SwiftData

/// 県詳細シート
struct PrefectureDetailSheet: View {
    @Bindable var prefecture: Prefecture

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showAddVisit = false
    @State private var editingVisit: Visit?
    @State private var showDeleteConfirmation = false
    @State private var visitToDelete: Visit?

    private var sortedVisits: [Visit] {
        prefecture.visits.sorted { $0.startDate > $1.startDate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                quickRecordButton
                addDetailButton
                visitList
            }
        }
        .sheet(isPresented: $showAddVisit) {
            VisitInputSheet(prefecture: prefecture, editingVisit: nil)
        }
        .sheet(item: $editingVisit) { visit in
            VisitInputSheet(prefecture: prefecture, editingVisit: visit)
        }
        .alert("訪問記録を削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除する", role: .destructive) {
                if let visit = visitToDelete {
                    if let filename = visit.photoFilename {
                        PhotoStorageManager.delete(filename: filename)
                    }
                    modelContext.delete(visit)
                }
            }
        } message: {
            Text("この操作は元に戻せません")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                // 読み仮名
                Text(spacedKana(prefecture.nameKana))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.irohaSumi3)
                    .tracking(2.5)

                // 県名
                Text(prefecture.name)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.irohaSumi)

                // 地方名
                Text("\(prefecture.region.localizedName)地方 \u{00B7} \(prefecture.id)")
                    .font(.system(size: 13))
                    .foregroundColor(.irohaSumi3)
            }

            Spacer()

            // 訪問数（塗りかけ）
            VStack(spacing: 3) {
                NurikakeNumber(value: prefecture.visitCount, fontSize: 44)
                Text("回訪問")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.irohaSumi3)
                    .tracking(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .border(width: 0.5, edges: [.bottom], color: Color.irohaSumi.opacity(0.07))
    }

    // MARK: - Quick record button

    private var quickRecordButton: some View {
        Button {
            let visit = Visit(prefectureName: prefecture.name, startDate: Date())
            visit.prefecture = prefecture
            modelContext.insert(visit)
        } label: {
            HStack(spacing: 10) {
                Text("＋")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(.white.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text("今日の訪問を記録")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(Date().formatted(date: .long, time: .omitted)) \u{00B7} 1タップで保存")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                Text("\u{203A}")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.irohaFuji)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.irohaFuji.opacity(0.28), radius: 6, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Add detail button

    private var addDetailButton: some View {
        HStack {
            Spacer()
            Button {
                showAddVisit = true
            } label: {
                Text("＋ 詳細で追加")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.irohaFujiDk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.irohaFujiLt.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.irohaFujiLt, lineWidth: 0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Visit list

    private var visitList: some View {
        List {
            ForEach(Array(sortedVisits.enumerated()), id: \.element.id) { index, visit in
                visitCard(visit: visit, index: index)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .listRowSeparatorTint(Color.irohaSumi.opacity(0.07))
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            visitToDelete = visit
                            showDeleteConfirmation = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        Button {
                            editingVisit = visit
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .tint(Color.irohaFuji)
                    }
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .frame(minHeight: CGFloat(sortedVisits.count) * 60)
        .padding(.top, 6)
    }

    private func visitCard(visit: Visit, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Nurikake dot
            Circle()
                .fill(Color.visitColor(count: index + 1))
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(visit.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 15, weight: .bold))

                    if visit.effectiveTag != .none {
                        VisitTagBadge(tag: visit.effectiveTag)
                    }
                }

                if !visit.note.isEmpty {
                    Text(visit.note)
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi2)
                        .lineHeight(1.5)
                } else {
                    Text("メモなし")
                        .font(.system(size: 13))
                        .foregroundColor(.irohaSumi3)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                editingVisit = visit
            } label: {
                Label("編集", systemImage: "pencil")
            }
            Button(role: .destructive) {
                visitToDelete = visit
                showDeleteConfirmation = true
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func spacedKana(_ kana: String) -> String {
        kana.map { String($0) }.joined(separator: " ")
    }
}

// MARK: - Text line height extension

extension View {
    func lineHeight(_ multiplier: CGFloat) -> some View {
        self.lineSpacing((multiplier - 1) * 13)
    }
}

// MARK: - VisitInputSheet

/// 訪問の記録 / 編集シート
struct VisitInputSheet: View {
    let prefecture: Prefecture
    let editingVisit: Visit?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var visitDate = Date()
    @State private var selectedTag: VisitTag = .none
    @State private var memo = ""

    private var isEditing: Bool { editingVisit != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Prefecture header
                VStack(alignment: .leading, spacing: 3) {
                    Text(spacedKana(prefecture.nameKana))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.irohaSumi3)
                        .tracking(2.5)
                    Text(prefecture.name)
                        .font(.system(size: 22, weight: .light, design: .serif))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Form
                VStack(spacing: 0) {
                    // Date
                    formField(label: "訪問日") {
                        DatePicker("", selection: $visitDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            .labelsHidden()
                    }

                    // Tag
                    formField(label: "訪問スタイル") {
                        HStack(spacing: 6) {
                            ForEach([VisitTag.dayTrip, .stay, .lived], id: \.rawValue) { tag in
                                Button {
                                    selectedTag = selectedTag == tag ? .none : tag
                                } label: {
                                    Text(tag.displayName)
                                        .font(.system(size: 14, weight: selectedTag == tag ? .bold : .medium))
                                        .foregroundColor(selectedTag == tag ? .irohaFujiDk : .irohaSumi3)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTag == tag
                                                ? Color.irohaFuji.opacity(0.12)
                                                : Color.irohaWashi2
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedTag == tag ? Color.irohaFuji : Color.irohaWashi3,
                                                    lineWidth: 0.5
                                                )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    // Memo
                    formField(label: "メモ") {
                        TextField("旅の思い出を残しておこう…", text: $memo, axis: .vertical)
                            .font(.system(size: 15))
                            .frame(minHeight: 44)
                            .padding(10)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.irohaWashi3, lineWidth: 0.5)
                            )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color.irohaWashi)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "訪問を編集" : "訪問を記録")
                        .font(.system(size: 16, weight: .bold))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundColor(.irohaSumi3)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.irohaFujiDk)
                }
            }
            .onAppear {
                if let visit = editingVisit {
                    visitDate = visit.startDate
                    selectedTag = visit.effectiveTag
                    memo = visit.note
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color.irohaWashi)
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.irohaSumi3)
                .tracking(1)
            content()
        }
        .padding(.bottom, 12)
    }

    private func save() {
        if let visit = editingVisit {
            visit.startDate = visitDate
            visit.tag = selectedTag
            visit.note = memo
        } else {
            let visit = Visit(
                prefectureName: prefecture.name,
                startDate: visitDate,
                note: memo,
                tag: selectedTag
            )
            visit.prefecture = prefecture
            modelContext.insert(visit)
        }
        dismiss()
    }

    private func spacedKana(_ kana: String) -> String {
        kana.map { String($0) }.joined(separator: " ")
    }
}

// MARK: - Preview

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            PrefectureDetailSheet(
                prefecture: Prefecture(
                    id: 26, name: "京都府", nameKana: "きょうとふ",
                    region: .kinki, latitude: 35.0, longitude: 135.7,
                    distanceFromTokyo: 453
                )
            )
            .presentationDetents([.fraction(0.7)])
        }
        .modelContainer(for: [Prefecture.self, Visit.self], inMemory: true)
}
