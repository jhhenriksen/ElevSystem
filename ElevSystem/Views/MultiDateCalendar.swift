import SwiftUI

/// Månadskalender (måndag först) där flera dagar kan väljas.
struct MultiDateCalendar: View {
    @Binding var selection: Set<Date>   // startOfDay
    @State private var month = Date()

    private var cal: Calendar { var c = Calendar.current; c.firstWeekday = 2; return c }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }.buttonStyle(.borderless)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 8), spacing: 2) {
                Text("v.").font(.caption2).foregroundStyle(.secondary)
                ForEach(["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"], id: \.self) {
                    Text($0).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(weeks, id: \.self) { week in
                    Text("\(cal.component(.weekOfYear, from: week[0]))").font(.caption2).foregroundStyle(.secondary)
                    ForEach(week, id: \.self) { day in dayCell(day) }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = cal.isDate(day, equalTo: month, toGranularity: .month)
        let on = selection.contains(day)
        return Text("\(cal.component(.day, from: day))")
            .frame(maxWidth: .infinity, minHeight: 28)
            .background(on ? Color.accentColor : (cal.isDateInToday(day) ? Color.secondary.opacity(0.2) : .clear), in: RoundedRectangle(cornerRadius: 6))
            .foregroundStyle(on ? Color.white : (inMonth ? Color.primary : Color.secondary.opacity(0.5)))
            .contentShape(Rectangle())
            .onTapGesture { if on { selection.remove(day) } else { selection.insert(day) } }
    }

    private var weeks: [[Date]] {
        guard let interval = cal.dateInterval(of: .month, for: month),
              let start = cal.dateInterval(of: .weekOfYear, for: interval.start)?.start else { return [] }
        var result: [[Date]] = []
        var d = start
        while d < interval.end {
            result.append((0..<7).map { cal.date(byAdding: .day, value: $0, to: d)! })
            d = cal.date(byAdding: .day, value: 7, to: d)!
        }
        return result
    }

    private func shift(_ n: Int) { month = cal.date(byAdding: .month, value: n, to: month) ?? month }
}
