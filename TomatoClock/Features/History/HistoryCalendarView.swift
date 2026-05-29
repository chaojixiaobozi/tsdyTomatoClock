import SwiftUI

struct HistoryCalendarView: View {
    let todayDay: String
    let todayCount: Int
    let history: [String: Int]

    @Environment(\.dismiss) private var dismiss
    @State private var displayedYear: Int
    @State private var displayedMonth: Int

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    init(todayDay: String, todayCount: Int, history: [String: Int]) {
        self.todayDay = todayDay
        self.todayCount = todayCount
        self.history = history
        let current = HistoryMonthGridBuilder.currentYearMonth()
        _displayedYear = State(initialValue: current.year)
        _displayedMonth = State(initialValue: current.month)
    }

    private var grid: HistoryMonthGrid {
        HistoryMonthGridBuilder.build(
            year: displayedYear,
            month: displayedMonth,
            todayDay: todayDay,
            todayCount: todayCount,
            history: history,
            calendar: calendar
        )
    }

    var body: some View {
        ZStack {
            TomatoPalette.settingsBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        monthNavigator
                        weekdayHeaderRow
                        calendarGrid
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 420, minHeight: 480)
    }

    private var header: some View {
        HStack {
            Text("历史记录")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white.opacity(0.95))
            Spacer()
            Button("关闭") {
                dismiss()
            }
            .buttonStyle(SettingsChromeSecondaryButtonStyle())
            .accessibilityIdentifier("history.closeButton")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TomatoPalette.settingsChromeBar)
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                stepMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(HistoryMonthNavButtonStyle())
            .accessibilityIdentifier("history.previousMonth")

            Spacer()

            Text(grid.title)
                .font(.title3.weight(.semibold))
                .accessibilityIdentifier("history.monthTitle")

            Spacer()

            Button {
                stepMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(HistoryMonthNavButtonStyle())
            .accessibilityIdentifier("history.nextMonth")
        }
    }

    private var weekdayHeaderRow: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(grid.weekdayHeaders.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(grid.cells.enumerated()), id: \.offset) { _, cell in
                dayCell(cell)
            }
        }
        .accessibilityIdentifier("history.calendar")
    }

    @ViewBuilder
    private func dayCell(_ cell: HistoryDayCell) -> some View {
        if cell.isInCurrentMonth, let day = cell.dayOfMonth, let dayKey = cell.calendarDay {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.subheadline.weight(cell.isToday ? .semibold : .regular))
                if let count = cell.count {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(" ")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TomatoPalette.settingsCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        cell.isToday ? TomatoPalette.workAccent.opacity(0.85) : TomatoPalette.settingsCardStroke,
                        lineWidth: cell.isToday ? 1.5 : 1
                    )
            )
            .accessibilityIdentifier("history.dayCell.\(dayKey)")
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 52)
        }
    }

    private func stepMonth(by delta: Int) {
        let next = HistoryMonthGridBuilder.adjacentMonth(
            year: displayedYear,
            month: displayedMonth,
            delta: delta
        )
        displayedYear = next.year
        displayedMonth = next.month
    }
}
