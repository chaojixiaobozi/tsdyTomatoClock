import SwiftUI

@main
struct TomatoClockApp: App {
    var body: some Scene {
        WindowGroup {
            TimerRootView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
