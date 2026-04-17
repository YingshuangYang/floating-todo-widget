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

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isDone: Bool = false

    init(id: UUID = UUID(), text: String, isDone: Bool = false) {
        self.id = id
        self.text = text
        self.isDone = isDone
    }
}

final class TodoStore: ObservableObject {
    private static let storageKey = "FloatingTodoWidget.tasks"

    @Published var tasks: [TaskItem] {
        didSet {
            saveTasks()
        }
    }

    init() {
        if
            let data = UserDefaults.standard.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([TaskItem].self, from: data),
            !decoded.isEmpty
        {
            self.tasks = decoded
        } else {
            self.tasks = Self.defaultTasks
        }
    }

    private static let defaultTasks: [TaskItem] = [
        TaskItem(text: "See a doctor"),
        TaskItem(text: "PPT draft"),
        TaskItem(text: "Snowflake video"),
        TaskItem(text: "Apply 10 position"),
        TaskItem(text: "PPT skills install"),
        TaskItem(text: ""),
        TaskItem(text: ""),
        TaskItem(text: ""),
        TaskItem(text: ""),
        TaskItem(text: ""),
        TaskItem(text: ""),
        TaskItem(text: "")
    ]

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

    func numberLabel(at index: Int) -> String {
        guard tasks.indices.contains(index) else { return "" }
        let item = tasks[index]
        let visibleItems = tasks[0...index].filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        return "No.\(visibleItems.count)"
    }

    func syncTaskState(at index: Int) {
        let hasText = !tasks[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if !hasText {
            tasks[index].isDone = false
        }
    }

    func focusableIndex(after index: Int) -> Int? {
        guard !tasks.isEmpty else { return nil }
        return min(index + 1, tasks.count - 1)
    }

    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
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
        ZStack {
            LinearGradient(
                colors: [WidgetTheme.backgroundTop, WidgetTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                header

                HStack(alignment: .top, spacing: 18) {
                    taskPanel
                    statusPanel
                }
            }
        }
        .frame(width: 700, height: 540)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                .padding(12)
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily to do list")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(WidgetTheme.title)

                Text("A calm space for today's priorities")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetTheme.secondary)
            }

            Spacer()

            Text("Today")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(WidgetTheme.accentSoft)
                )
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
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
                        store.syncTaskState(at: index)
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
        .frame(width: 430)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
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
        .windowResizability(.contentSize)
    }
}
