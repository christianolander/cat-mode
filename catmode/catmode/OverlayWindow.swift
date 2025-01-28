import SwiftUI
import MASShortcut

// Custom view that only allows clicks on the toggle button
class OverlayContainerView: NSView {
    private let toggleButton: NSButton
    
    init(frame: NSRect, toggleButton: NSButton) {
        self.toggleButton = toggleButton
        super.init(frame: frame)
        wantsLayer = true
        addSubview(toggleButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        if toggleButton.frame.contains(point) {
            return toggleButton
        }
        return nil
    }
}

class OverlayWindow: NSWindow {
    private var tintWindow: NSWindow?
    
    var catModeManager: CatModeManager? {
        didSet {
            if let manager = catModeManager {
                self.contentView = NSHostingView(
                    rootView: OverlayView()
                        .environmentObject(manager)
                )
            }
        }
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    init() {
        // Create a rect just below the menu bar
        let menuBarHeight = NSStatusBar.system.thickness
        let screenFrame = NSScreen.main?.frame ?? .zero
        let windowFrame = NSRect(
            x: 0,
            y: screenFrame.height - menuBarHeight - 30, // 30 is the height of our bar
            width: screenFrame.width,
            height: 30
        )
        
        super.init(
            contentRect: windowFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.backgroundColor = .black.withAlphaComponent(0.8)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        setupTintWindow()
        
        // Listen for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTintWindow),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    private func setupTintWindow() {
        // Get the frame that encompasses all screens
        let frame = NSScreen.screens.reduce(NSRect.zero) { union, screen in
            union.union(screen.frame)
        }
        
        tintWindow = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        tintWindow?.level = .floating
        tintWindow?.backgroundColor = .black.withAlphaComponent(0.2)
        tintWindow?.isOpaque = false
        tintWindow?.hasShadow = false
        tintWindow?.ignoresMouseEvents = true
        tintWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
    }
    
    @objc private func updateTintWindow() {
        let frame = NSScreen.screens.reduce(NSRect.zero) { union, screen in
            union.union(screen.frame)
        }
        tintWindow?.setFrame(frame, display: true)
    }
    
    func show() {
        self.orderFront(nil)
        tintWindow?.orderFront(nil)
    }
    
    func hide() {
        self.orderOut(nil)
        tintWindow?.orderOut(nil)
    }
    
    deinit {
        tintWindow?.close()
        NotificationCenter.default.removeObserver(self)
    }
}

struct OverlayView: View {
    @EnvironmentObject var catModeManager: CatModeManager
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "cat.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text("Cat Mode Active")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text("Press \(catModeManager.currentShortcut?.description ?? "shortcut") to disable")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.7))
    }
}
