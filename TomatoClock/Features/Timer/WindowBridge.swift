import AppKit
import SwiftUI

struct WindowBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let w = nsView.window {
                MainWindowHolder.shared.keyWindow = w
            }
        }
    }
}
