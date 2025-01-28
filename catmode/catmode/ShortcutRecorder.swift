import SwiftUI
import MASShortcut
import os.log

struct ShortcutRecorder: NSViewRepresentable {
    private let logger = Logger(subsystem: "com.example.CatMode", category: "ShortcutRecorder")
    let shortcut: MASShortcut?
    let onChange: (MASShortcut?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        logger.debug("Creating MASShortcutView")
        let view = MASShortcutView()
        view.associatedUserDefaultsKey = "CatModeToggleShortcut"
        view.shortcutValueChange = { [onChange, logger] sender in
            guard let shortcutView = sender as? MASShortcutView else {
                logger.error("Failed to cast sender to MASShortcutView")
                return
            }
            logger.debug("Shortcut changed: \(String(describing: shortcutView.shortcutValue))")
            onChange(shortcutView.shortcutValue as? MASShortcut)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? MASShortcutView else {
            logger.error("Failed to cast nsView to MASShortcutView")
            return
        }
        logger.debug("Updating view with shortcut: \(String(describing: shortcut))")
    }
}
