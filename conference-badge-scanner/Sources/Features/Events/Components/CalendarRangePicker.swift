import SwiftUI
import UIKit

/// SwiftUI wrapper for Apple's UICalendarView using multi-date selection to capture a range.
/// Users tap two dates (start and end) in a single calendar interaction. Same-day ranges supported.
struct CalendarRangePicker: UIViewRepresentable {
    @Binding var range: DateInterval?

    var earliestDate: Date? = nil
    var latestDate: Date? = nil
    var calendar: Calendar = .current

    func makeUIView(context: Context) -> UICalendarView {
        let view = UICalendarView()
        view.calendar = calendar
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground

        // Configure available range if provided
        if let earliestDate, let latestDate {
            view.availableDateRange = DateInterval(start: earliestDate, end: latestDate)
        } else if let earliestDate {
            view.availableDateRange = DateInterval(start: earliestDate, end: .distantFuture)
        } else if let latestDate {
            view.availableDateRange = DateInterval(start: .distantPast, end: latestDate)
        }

        let selection = UICalendarSelectionMultiDate(delegate: context.coordinator)
        view.selectionBehavior = selection

        // Do not preselect by default; user will pick start then end.

        return view
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        uiView.calendar = calendar

        if let earliestDate, let latestDate {
            uiView.availableDateRange = DateInterval(start: earliestDate, end: latestDate)
        } else if let earliestDate {
            uiView.availableDateRange = DateInterval(start: earliestDate, end: .distantFuture)
        } else if let latestDate {
            uiView.availableDateRange = DateInterval(start: .distantPast, end: latestDate)
        }

        if let selection = uiView.selectionBehavior as? UICalendarSelectionMultiDate {
            let selected = selection.selectedDates
            let desired: [DateComponents]
            if let range {
                desired = context.coordinator.dayComponentsInRange(range, calendar: calendar)
            } else {
                desired = []
            }
            if selected != desired {
                selection.setSelectedDates(desired, animated: false)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UICalendarSelectionMultiDateDelegate {
        var parent: CalendarRangePicker
        init(_ parent: CalendarRangePicker) { self.parent = parent }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
            handleSelectionChange(selection)
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
            handleSelectionChange(selection)
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, canSelectDate dateComponents: DateComponents) -> Bool {
            true
        }

        private func handleSelectionChange(_ selection: UICalendarSelectionMultiDate) {
            let days = selection.selectedDates
            // 0 taps → clear
            guard !days.isEmpty else { parent.range = nil; return }

            // 1 tap → start only
            if days.count == 1, let start = parent.calendar.date(from: days[0]) {
                let startOfDay = parent.calendar.startOfDay(for: start)
                parent.range = DateInterval(start: startOfDay, end: startOfDay)
                return
            }

            // 2+ taps → min..max
            let sorted = days.sorted { lhs, rhs in
                let l = parent.calendar.date(from: lhs) ?? .distantPast
                let r = parent.calendar.date(from: rhs) ?? .distantPast
                return l < r
            }
            guard let first = sorted.first, let last = sorted.last,
                  let start = parent.calendar.date(from: first),
                  let end = parent.calendar.date(from: last) else {
                parent.range = nil; return
            }
            let startOfDay = parent.calendar.startOfDay(for: start)
            let endOfDay = parent.calendar.startOfDay(for: end)
            parent.range = DateInterval(start: startOfDay, end: endOfDay)
        }

        fileprivate func dayComponentsInRange(_ range: DateInterval, calendar: Calendar) -> [DateComponents] {
            var result: [DateComponents] = []
            var day = calendar.startOfDay(for: range.start)
            let end = calendar.startOfDay(for: range.end)
            while day <= end {
                let comps = calendar.dateComponents([.year, .month, .day], from: day)
                result.append(comps)
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            return result
        }
    }
}


