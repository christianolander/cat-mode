import SwiftUI
import Carbon
import CoreGraphics
import ServiceManagement
import os.log
import MASShortcut

class CatModeManager: ObservableObject {
    internal let logger = Logger(subsystem: "com.example.CatMode", category: "CatModeManager")
    private let shortcutKey = "CatModeToggleShortcut"
    private lazy var shortcutBinder: MASShortcutBinder = MASShortcutBinder.shared()!
    
    // Keep a strong reference to self in the app delegate
    internal static var shared: CatModeManager?
    
    // Serial queue for toggle operations
    private let toggleQueue = DispatchQueue(label: "com.example.CatMode.toggleQueue")
    private var isToggling = false
    
    var onActiveStateChanged: ((Bool) -> Void)?
    
    @Published var isRecordingShortcut = false
    @Published var isActive = false {
        didSet {
            self.logger.debug("Cat Mode isActive changed to: \(self.isActive)")
            if self.isActive {
                if self.overlayWindow == nil {
                    self.setupOverlayWindow()
                }
                if self.showOverlay {
                    self.overlayWindow?.show()
                }
                self.enableEventTap()
            } else {
                self.overlayWindow?.hide()
                self.disableEventTap()
            }
        }
    }
    @Published var showOverlay = true
    @Published var isPreferencesOpen = false {
        didSet {
            self.logger.debug("Preferences open state changed to: \(self.isPreferencesOpen)")
            if self.isPreferencesOpen {
                DispatchQueue.main.async { [weak self] in
                    self?.isActive = false
                }
            }
        }
    }
    @Published var startAtLogin = false {
        didSet {
            self.setLaunchAtLogin(enabled: self.startAtLogin)
        }
    }
    @Published private(set) var currentShortcut: MASShortcut? {
        didSet {
            self.logger.debug("Current shortcut changed to: \(String(describing: self.currentShortcut))")
            
            // Save shortcut to UserDefaults
            if let shortcut = self.currentShortcut {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: true)
                    self.logger.debug("Saving shortcut to UserDefaults")
                    UserDefaults.standard.set(data, forKey: self.shortcutKey)
                } catch {
                    self.logger.error("Failed to archive shortcut: \(error.localizedDescription)")
                }
            } else {
                self.logger.debug("Removing shortcut from UserDefaults")
                UserDefaults.standard.removeObject(forKey: self.shortcutKey)
            }
            
            // Update binding after saving
            self.bindCurrentShortcut()
        }
    }
    @Published var countdownSeconds = 10
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var overlayWindow: OverlayWindow?
    
    init() {
        self.logger.debug("Initializing CatModeManager")
        
        // Maintain a strong reference to self
        Self.shared = self
        
        setupEventTap()
        requestAccessibilityPermissions()
        
        // Initialize shortcut handling
        self.logger.debug("Initialized shortcut binder: \(String(describing: self.shortcutBinder))")
        
        // Load saved shortcut or use default
        if let data = UserDefaults.standard.data(forKey: self.shortcutKey) {
            self.logger.debug("Found saved shortcut data")
            do {
                if let savedShortcut = try NSKeyedUnarchiver.unarchivedObject(ofClass: MASShortcut.self, from: data) {
                    self.logger.debug("Successfully loaded saved shortcut: \(savedShortcut.description)")
                    self.currentShortcut = savedShortcut
                    self.logger.debug("About to bind saved shortcut")
                    self.bindCurrentShortcut()
                } else {
                    self.logger.error("Failed to unarchive shortcut data")
                }
            } catch {
                self.logger.error("Error unarchiving shortcut: \(error.localizedDescription)")
            }
        } else {
            // Default shortcut: Control + Option + K
            self.logger.debug("No saved shortcut found, using default")
            self.currentShortcut = MASShortcut(keyCode: Int(kVK_ANSI_K), modifierFlags: [.control, .option])
            self.logger.debug("About to bind default shortcut")
            self.bindCurrentShortcut()
        }
    }
    
    deinit {
        self.logger.debug("CatModeManager is being deallocated")
        self.shortcutBinder.breakBinding(withDefaultsKey: self.shortcutKey)
        Self.shared = nil
    }
    
    func updateShortcut(_ newShortcut: MASShortcut?) {
        self.logger.debug("Updating shortcut to: \(String(describing: newShortcut))")
        
        // Break existing binding first
        self.shortcutBinder.breakBinding(withDefaultsKey: self.shortcutKey)
        self.logger.debug("Broke existing binding")
        
        if let shortcut = newShortcut {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: true)
                UserDefaults.standard.set(data, forKey: self.shortcutKey)
                self.currentShortcut = shortcut
                self.logger.debug("Saved new shortcut to UserDefaults")
                
                // Bind the shortcut
                self.logger.debug("About to bind new shortcut")
                self.shortcutBinder.bindShortcut(withDefaultsKey: self.shortcutKey) { [weak self] in
                    guard let self = self else { return }
                    self.logger.debug("Shortcut triggered! isActive: \(self.isActive), isPreferencesOpen: \(self.isPreferencesOpen)")
                    
                    if self.isActive {
                        // Force deactivate if Cat Mode is on
                        self.logger.debug("Cat Mode is active, forcing deactivation")
                        DispatchQueue.main.async {
                            self.isActive = false
                            self.logger.debug("Set isActive to false")
                        }
                    } /*else if !self.isPreferencesOpen {
                        // Normal toggle if Cat Mode is off
                        self.logger.debug("Cat Mode is inactive, doing normal toggle")
                        self.toggleCatMode()
                    }*/
                }
            } catch {
                self.logger.error("Failed to save shortcut: \(error.localizedDescription)")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: self.shortcutKey)
            self.currentShortcut = nil
            self.logger.debug("Removed shortcut from UserDefaults")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    func bindCurrentShortcut() {
        self.logger.debug("Binding current shortcut")
        
        // Break any existing binding
        shortcutBinder.breakBinding(withDefaultsKey: shortcutKey)
        
        // Only bind if we have a shortcut
        if let shortcut = self.currentShortcut {
            shortcutBinder.bindShortcut(withDefaultsKey: shortcutKey) { [weak self] in
                guard let self = self else { return }
                self.logger.debug("Shortcut triggered! isActive: \(self.isActive), isPreferencesOpen: \(self.isPreferencesOpen)")
                
                if self.isActive {
                    // Force deactivate if Cat Mode is on
                    self.logger.debug("Cat Mode is active, forcing deactivation")
                    DispatchQueue.main.async {
                        self.isActive = false
                        self.logger.debug("Set isActive to false")
                    }
                } else if !self.isPreferencesOpen {
                    // Normal toggle if Cat Mode is off
                    self.logger.debug("Cat Mode is inactive, doing normal toggle")
                    self.toggleCatMode()
                }
            }
            self.logger.debug("Successfully bound shortcut: \(shortcut.description)")
        }
    }
    
    func toggleCatMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.logger.debug("Toggle requested (isPreferencesOpen: \(self.isPreferencesOpen), isActive: \(self.isActive))")
            
            if self.isPreferencesOpen {
                self.logger.debug("Cannot toggle - preferences are open")
                return
            }
            
            self.logger.debug("About to toggle isActive from \(self.isActive) to \(!self.isActive)")
            self.isActive.toggle()
        }
    }
    
    private func setupEventTap() {
        logger.debug("Setting up event tap")
        
        // Break up event mask into smaller parts
        let keyMask = (1 << CGEventType.keyDown.rawValue) |
                     (1 << CGEventType.keyUp.rawValue)
        
        let mouseMask = (1 << CGEventType.leftMouseDown.rawValue) |
                       (1 << CGEventType.leftMouseUp.rawValue) |
                       (1 << CGEventType.rightMouseDown.rawValue) |
                       (1 << CGEventType.rightMouseUp.rawValue)
        
        let otherMouseMask = (1 << CGEventType.otherMouseDown.rawValue) |
                            (1 << CGEventType.otherMouseUp.rawValue) |
                            (1 << CGEventType.mouseMoved.rawValue) |
                            (1 << CGEventType.scrollWheel.rawValue)
        
        let systemDefinedEventType = CGEventType(rawValue: 14)!

        // Then build a mask for the event tap:
        let systemMask: CGEventMask = 1 << systemDefinedEventType.rawValue

        
        
        let eventMask = CGEventMask(keyMask) | CGEventMask(mouseMask) | CGEventMask(otherMouseMask) | systemMask
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            logger.error("Failed to create event tap")
            return
        }
        
        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        
        if let runLoopSource = self.runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            logger.debug("Event tap enabled successfully")
        }
    }
    
    private func enableEventTap() {
        guard let tap = eventTap else {
            logger.error("Cannot enable event tap - tap is nil")
            return
        }
        
        logger.debug("Enabling event tap")
        CGEvent.tapEnable(tap: tap, enable: true)
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            logger.debug("Added run loop source")
        } else {
            logger.error("Run loop source is nil")
        }
    }
    
    private func disableEventTap() {
        guard let tap = eventTap else {
            logger.error("Cannot disable event tap - tap is nil")
            return
        }
        
        logger.debug("Disabling event tap")
        CGEvent.tapEnable(tap: tap, enable: false)
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            logger.debug("Removed run loop source")
        }
    }
    
    private func requestAccessibilityPermissions() {
        // Request both Accessibility and Input Monitoring permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        
        // Check/request Accessibility permission
        let accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        logger.debug("Accessibility permission granted: \(accessibilityGranted)")
        
        // Request Input Monitoring permission by trying to create an event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue) |
                       (1 << CGEventType.mouseMoved.rawValue) |
                       (1 << 14) // System defined events (media keys)
        
        if let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in 
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) {
            logger.debug("Input Monitoring permission granted")
            // Clean up the test tap
            if let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, testTap, 0) {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        } else {
            logger.debug("Input Monitoring permission needed")
            // Show an alert to guide the user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Additional Permissions Required"
                alert.informativeText = "Cat Mode needs both Accessibility and Input Monitoring permissions to work properly.\n\nPlease enable both in System Settings → Privacy & Security → Accessibility AND Input Monitoring."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // Open Privacy & Security settings
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
    
    func setLaunchAtLogin(enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
    
    private func setupOverlayWindow() {
        overlayWindow = OverlayWindow()
        overlayWindow?.catModeManager = self
        overlayWindow?.orderFront(nil)
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let manager = refcon.map({ Unmanaged<CatModeManager>.fromOpaque($0).takeUnretainedValue() }),
          manager.isActive else {
        return Unmanaged.passRetained(event)
    }
    
    // Only log non-mouse-move events to reduce noise
    if type != .mouseMoved {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags.rawValue
        manager.logger.debug("Event tap received: type=\(type.rawValue), keyCode=\(keyCode), flags=\(flags)")
    }
    
    // Block mouse events
    if type == .mouseMoved || type == .leftMouseDown || type == .leftMouseUp ||
        type == .rightMouseDown || type == .rightMouseUp ||
        type == .otherMouseDown || type == .otherMouseUp {
        return nil
    }
   
  
    
    
    // Block system-defined events (media keys, function keys, etc)
    if type.rawValue == 14 {  // System defined events
      
            return nil
        }
        
        
    
    
    // Block keyboard events
    if type == .keyDown || type == .keyUp {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        print("keyCode: \(keyCode)")
        let flags = event.flags.rawValue
        
        // Check if this is our shortcut using MASShortcut's own matching
        if let shortcut = manager.currentShortcut,
           type == .keyDown {  // Only check on keyDown to avoid double-triggering
            manager.logger.debug("Checking shortcut - Event: keyCode=\(keyCode), flags=\(flags)")
            
            // Create a temporary MASShortcut from the event to use isEqual
            let eventShortcut = MASShortcut(keyCode: Int(keyCode), modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)))
            
            if shortcut.isEqual(eventShortcut) {
                manager.logger.debug("Shortcut match! Allowing through")
                DispatchQueue.main.async {
                    manager.isActive = false
                    manager.logger.debug("Forced deactivation via event tap")
                }
                return Unmanaged.passRetained(event)
            }
        }
        
        // Block all keyboard events including special keys
        let isFunctionKey = (keyCode >= 122 && keyCode <= 129)  // F1-F8
            || (keyCode >= 100 && keyCode <= 111)  // F9-F20
            || keyCode == 63  // fn key
            || (keyCode >= 145 && keyCode <= 147)  // brightness controls
            || (keyCode >= 160 && keyCode <= 162)  // mission control
            || (keyCode >= 96 && keyCode <= 99)  // F13-F16
        
        if isFunctionKey {
            manager.logger.debug("Blocking function/special key: \(keyCode)")
        } else {
            manager.logger.debug("Blocking regular key: \(keyCode)")
        }
        
        return nil
    }
    
    return Unmanaged.passRetained(event)
}
