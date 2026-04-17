import SwiftUI
import AppKit

enum WidgetTheme {
    static let backgroundTop = Color(red: 0.95, green: 0.96, blue: 0.98)
    static let backgroundBottom = Color(red: 0.91, green: 0.93, blue: 0.96)
    static let shell = Color.white.opacity(0.74)
    static let card = Color.white.opacity(0.88)
    static let line = Color.black.opacity(0.08)
    static let lineSoft = Color.black.opacity(0.04)
    static let title = Color(red: 0.13, green: 0.14, blue: 0.17)
    static let secondary = Color(red: 0.43, green: 0.46, blue: 0.52)
    static let accent = Color(red: 0.43, green: 0.62, blue: 0.96)
    static let accentSoft = Color(red: 0.88, green: 0.93, blue: 1.0)
    static let ring = Color(red: 0.56, green: 0.80, blue: 0.62)
    static let ringTrack = Color.white.opacity(0.7)
}

enum TaskSource: String, Codable {
    case manual
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isDone: Bool
    var source: TaskSource
    var sourceID: String?

    init(
        id: UUID = UUID(),
        text: String,
        isDone: Bool = false,
        source: TaskSource = .manual,
        sourceID: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.source = source
        self.sourceID = sourceID
    }
}

struct DailyTaskRecord: Codable {
    var dayKey: String
    var tasks: [TaskItem]
}

@MainActor
final class TodoStore: ObservableObject {
    private static let recordsKey = "FloatingTodoWidget.dailyRecords"
    private static let minimumRowCount = 12

    @Published var tasks: [TaskItem] {
        didSet {
            saveCurrentRecord()
        }
    }

    @Published var currentDayKey: String
    private let calendar = Calendar.current
    private var records: [String: DailyTaskRecord]

    init() {
        self.records = Self.loadRecords()
        let initialDayKey = Self.dayKey(for: Date())
        self.currentDayKey = initialDayKey

        if let record = records[initialDayKey] {
            self.tasks = Self.normalizedTasks(from: record.tasks)
        } else {
            self.tasks = Self.emptyTasks()
            saveCurrentRecord()
        }
    }

    var activeTaskCount: Int {
        tasks.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var completedTaskCount: Int {
        tasks.filter { item in
            let hasText = !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return hasText && item.isDone
        }.count
    }

    var completionPercent: Int {
        guard activeTaskCount > 0 else { return 0 }
        return Int((Double(completedTaskCount) / Double(activeTaskCount) * 100).rounded())
    }

    var missingPercent: Int {
        100 - completionPercent
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Self.date(from: currentDayKey))
    }

    var relativeDayLabel: String {
        let currentDate = Self.date(from: currentDayKey)

        if calendar.isDateInToday(currentDate) {
            return "Today"
        }
        if calendar.isDateInYesterday(currentDate) {
            return "Yesterday"
        }
        if calendar.isDateInTomorrow(currentDate) {
            return "Tomorrow"
        }
        return "Day View"
    }

    var isViewingToday: Bool {
        calendar.isDateInToday(Self.date(from: currentDayKey))
    }

    var todayFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }

    func numberLabel(at index: Int) -> String {
        guard tasks.indices.contains(index) else { return "" }
        let item = tasks[index]
        let visibleItems = tasks[0...index].filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        return "No.\(visibleItems.count)"
    }

    func miniPreviewTasks(limit: Int) -> [TaskItem] {
        let todayKey = Self.dayKey(for: Date())
        let sourceTasks: [TaskItem]

        if todayKey == currentDayKey {
            sourceTasks = tasks
        } else {
            sourceTasks = records[todayKey]?.tasks ?? []
        }

        let active = Self.normalizedTasks(from: sourceTasks)
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let unfinished = active.filter { !$0.isDone }
        let finished = active.filter(\.isDone)
        return Array((unfinished + finished).prefix(limit))
    }

    func todayCompletionPercent() -> Int {
        let todayKey = Self.dayKey(for: Date())
        let sourceTasks: [TaskItem]

        if todayKey == currentDayKey {
            sourceTasks = tasks
        } else {
            sourceTasks = records[todayKey]?.tasks ?? []
        }

        let active = sourceTasks.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !active.isEmpty else { return 0 }
        let doneCount = active.filter(\.isDone).count
        return Int((Double(doneCount) / Double(active.count) * 100).rounded())
    }

    func syncTaskState(at index: Int) {
        let hasText = !tasks[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !hasText {
            tasks[index].isDone = false
            tasks[index].source = .manual
            tasks[index].sourceID = nil
        }

        ensureBlankCapacity()
    }

    func handleTaskTextChange(at index: Int) {
        guard tasks.indices.contains(index) else { return }

        let hasText = !tasks[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !hasText {
            tasks[index].isDone = false
            tasks[index].source = .manual
            tasks[index].sourceID = nil
        }

        ensureBlankCapacity()
    }

    func focusableIndex(after index: Int) -> Int? {
        guard !tasks.isEmpty else { return nil }
        let next = min(index + 1, tasks.count - 1)
        return next
    }

    func refreshForTodayIfNeeded() {
        let todayKey = Self.dayKey(for: Date())
        guard todayKey != currentDayKey else { return }
        loadDay(todayKey)
    }

    func loadRelativeDay(_ offset: Int) {
        guard let targetDate = calendar.date(byAdding: .day, value: offset, to: Self.date(from: currentDayKey)) else {
            return
        }
        loadDay(Self.dayKey(for: targetDate))
    }

    func loadToday() {
        let todayKey = Self.dayKey(for: Date())
        loadDay(todayKey)
    }

    private func loadDay(_ dayKey: String) {
        saveCurrentRecord()
        currentDayKey = dayKey

        if let record = records[dayKey] {
            tasks = Self.normalizedTasks(from: record.tasks)
        } else {
            tasks = Self.emptyTasks()
            saveCurrentRecord()
        }
    }

    private func ensureBlankCapacity() {
        let nonEmptyCount = tasks.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        let minimumTotal = max(Self.minimumRowCount, nonEmptyCount + 2)
        if tasks.count < minimumTotal {
            tasks.append(contentsOf: Array(repeating: TaskItem(text: ""), count: minimumTotal - tasks.count))
        }
    }

    private func saveCurrentRecord() {
        let normalized = Self.normalizedTasks(from: tasks)
        var record = records[currentDayKey] ?? DailyTaskRecord(dayKey: currentDayKey, tasks: normalized)
        record.tasks = normalized
        records[currentDayKey] = record
        saveRecords()
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: Self.recordsKey)
    }

    private static func loadRecords() -> [String: DailyTaskRecord] {
        guard
            let data = UserDefaults.standard.data(forKey: recordsKey),
            let decoded = try? JSONDecoder().decode([String: DailyTaskRecord].self, from: data)
        else {
            return [:]
        }

        return decoded
    }

    private static func normalizedTasks(from tasks: [TaskItem]) -> [TaskItem] {
        let trimmed = tasks.map { item in
            var copy = item
            if copy.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                copy.text = ""
                copy.isDone = false
                copy.source = .manual
                copy.sourceID = nil
            }
            return copy
        }

        let trailingTrimmed = Array(trimmed.drop(while: { $0.text.isEmpty }).reversed().drop(while: { $0.text.isEmpty }).reversed())
        let base = trailingTrimmed.isEmpty ? [] : trailingTrimmed
        let minimumTotal = max(minimumRowCount, base.filter { !$0.text.isEmpty }.count + 2)
        let blanks = Array(repeating: TaskItem(text: ""), count: max(0, minimumTotal - base.count))
        return base + blanks
    }

    private static func emptyTasks() -> [TaskItem] {
        Array(repeating: TaskItem(text: ""), count: minimumRowCount)
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func date(from dayKey: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey) ?? Date()
    }
}

struct RingView: View {
    let percent: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetTheme.ringTrack, lineWidth: 18)

            Circle()
                .trim(from: 0, to: CGFloat(percent) / 100)
                .stroke(
                    LinearGradient(
                        colors: [WidgetTheme.ring, WidgetTheme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: WidgetTheme.accent.opacity(0.16), radius: 8, y: 4)

            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 108, height: 108)

            VStack(spacing: 4) {
                Text("\(percent)%")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.title)

                Text("done")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WidgetTheme.secondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
        }
        .frame(width: 170, height: 170)
    }
}

struct TodoRowView: View {
    @Binding var item: TaskItem
    let index: Int
    let number: String
    let focusedField: FocusState<Int?>.Binding
    let onTextChange: () -> Void
    let onSubmit: () -> Void

    private var shouldStrike: Bool {
        item.isDone && !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 10) {
            cell(width: 72) {
                ZStack {
                    Circle()
                        .fill(item.isDone ? WidgetTheme.accent.opacity(0.18) : Color.white.opacity(0.76))
                        .overlay(
                            Circle()
                                .stroke(item.isDone ? WidgetTheme.accent.opacity(0.6) : WidgetTheme.line, lineWidth: 1)
                        )
                        .frame(width: 22, height: 22)

                    Toggle("", isOn: $item.isDone)
                        .labelsHidden()
                        .toggleStyle(.checkbox)
                        .scaleEffect(0.9)
                        .disabled(item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            cell(width: 74) {
                Text(number)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.secondary)
            }

            cell(width: nil) {
                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        TextField("Add task", text: $item.text)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(item.isDone ? WidgetTheme.secondary : WidgetTheme.title)
                            .focused(focusedField, equals: index)
                            .submitLabel(.next)
                            .onChange(of: item.text) { _ in
                                onTextChange()
                            }
                            .onSubmit(onSubmit)

                        if shouldStrike {
                            Rectangle()
                                .fill(WidgetTheme.secondary.opacity(0.7))
                                .frame(height: 1.2)
                                .padding(.trailing, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(item.isDone ? Color.white.opacity(0.38) : Color.clear)
        )
        .opacity(item.isDone ? 0.72 : 1)
    }

    @ViewBuilder
    private func cell<Content: View>(width: CGFloat?, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(width: width)
            .padding(.vertical, 6)
    }
}

struct ContentView: View {
    @StateObject private var store = TodoStore()
    @FocusState private var focusedField: Int?

    var body: some View {
        GeometryReader { proxy in
            let isMiniMode = proxy.size.width < 640 || proxy.size.height < 430

            ZStack {
                LinearGradient(
                    colors: [WidgetTheme.backgroundTop, WidgetTheme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if isMiniMode {
                    miniModeView(height: proxy.size.height)
                } else {
                    VStack(spacing: 18) {
                        header

                        HStack(alignment: .top, spacing: 18) {
                            taskPanel
                            statusPanel
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .padding(.bottom, 20)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    .padding(12)
            )
            .onAppear {
                store.refreshForTodayIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                store.refreshForTodayIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                store.refreshForTodayIfNeeded()
            }
        }
        .frame(minWidth: 340, idealWidth: 860, maxWidth: .infinity, minHeight: 280, idealHeight: 620, maxHeight: .infinity)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily to do list")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.title)

                HStack(spacing: 10) {
                    dayNavButton(systemName: "chevron.left") {
                        store.loadRelativeDay(-1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.relativeDayLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(WidgetTheme.secondary)

                        Text(store.formattedDate)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(WidgetTheme.secondary.opacity(0.85))
                    }

                    dayNavButton(systemName: "chevron.right") {
                        store.loadRelativeDay(1)
                    }

                    Button("Today") {
                        store.loadToday()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(WidgetTheme.accentSoft.opacity(0.9))
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
    }

    private func dayNavButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.72))
                )
        }
        .buttonStyle(.plain)
    }

    private var taskPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                headerCell("Check", width: 72)
                headerCell("No.", width: 74)
                headerCell("Task", width: nil)
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()
                .overlay(WidgetTheme.lineSoft)
                .padding(.horizontal, 16)

            ForEach(store.tasks.indices, id: \.self) { index in
                TodoRowView(
                    item: $store.tasks[index],
                    index: index,
                    number: store.numberLabel(at: index),
                    focusedField: $focusedField,
                    onTextChange: {
                        store.handleTaskTextChange(at: index)
                    },
                    onSubmit: {
                        focusedField = store.focusableIndex(after: index)
                    }
                )

                if index < store.tasks.count - 1 {
                    Divider()
                        .overlay(WidgetTheme.lineSoft)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(minWidth: 420, idealWidth: 520, maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(WidgetTheme.shell)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(WidgetTheme.line, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
    }

    private func miniModeView(height: CGFloat) -> some View {
        let visibleCount = height < 340 ? 3 : 4
        let previewTasks = store.miniPreviewTasks(limit: visibleCount)
        let progress = store.todayCompletionPercent()

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetTheme.title)

                    Text(store.todayFormattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WidgetTheme.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(progress)%")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetTheme.title)

                    Text("done")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetTheme.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }

            VStack(spacing: 8) {
                if previewTasks.isEmpty {
                    miniEmptyState
                } else {
                    ForEach(Array(previewTasks.enumerated()), id: \.element.id) { offset, item in
                        miniTaskRow(item: item, index: offset + 1)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack {
                Label("Daily list", systemImage: "checklist")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WidgetTheme.secondary)

                Spacer()

                if !store.isViewingToday {
                    Button("Back to Today") {
                        store.loadToday()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.accent)
                }
            }
        }
        .padding(20)
    }

    private var miniEmptyState: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.62))
            .frame(maxWidth: .infinity, minHeight: 96)
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(WidgetTheme.accent)
                    Text("No tasks for today")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WidgetTheme.secondary)
                }
            )
    }

    private func miniTaskRow(item: TaskItem, index: Int) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(item.isDone ? WidgetTheme.accent.opacity(0.18) : Color.white.opacity(0.82))
                    .overlay(
                        Circle()
                            .stroke(item.isDone ? WidgetTheme.accent.opacity(0.55) : WidgetTheme.line, lineWidth: 1)
                    )
                    .frame(width: 18, height: 18)

                if item.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(WidgetTheme.accent)
                }
            }

            Text("No.\(index)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetTheme.secondary)
                .frame(width: 34, alignment: .leading)

            Text(item.text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(item.isDone ? WidgetTheme.secondary : WidgetTheme.title)
                .lineLimit(1)
                .strikethrough(item.isDone)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(item.isDone ? 0.45 : 0.66))
        )
    }

    private func headerCell(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(WidgetTheme.secondary)
            .textCase(.uppercase)
            .tracking(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .frame(width: width)
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Status")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetTheme.secondary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(store.completionPercent == 100 ? "Everything is done" : "Keep the day moving")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.title)
            }

            HStack {
                Spacer()
                RingView(percent: store.completionPercent)
                Spacer()
            }
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                summaryBox(title: "Completed", value: "\(store.completionPercent)%", tint: WidgetTheme.ring)
                summaryBox(title: "Missing", value: "\(store.missingPercent)%", tint: WidgetTheme.accent)
            }

            Spacer()
        }
        .padding(22)
        .frame(minWidth: 250, idealWidth: 300, maxWidth: 360, maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(WidgetTheme.card)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(WidgetTheme.line, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
    }

    private func summaryBox(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetTheme.secondary)

            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetTheme.title)
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.7))
        )
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard let window = NSApplication.shared.windows.first else { return }
            window.styleMask.insert(.resizable)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.minSize = NSSize(width: 340, height: 280)
            window.setContentSize(NSSize(width: 860, height: 620))
            window.center()
        }
    }
}

@main
struct FloatingTodoWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 860, height: 620)
    }
}
