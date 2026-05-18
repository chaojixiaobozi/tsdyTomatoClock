import AppKit

/// 保存主窗口引用并在阶段结束时前置（Domain 不依赖 AppKit）。
public final class MainWindowHolder: @unchecked Sendable {
    public static let shared = MainWindowHolder()

    public weak var keyWindow: NSWindow?

    public func bringForward() {
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let w = self.keyWindow {
                w.makeKeyAndOrderFront(nil)
            } else {
                NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
            }
        }
    }
}
