import SwiftUI

@main
struct CatModeApp: App {
    @StateObject private var catModeManager = CatModeManager()
    
    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(catModeManager)
        }
        MenuBarExtra("Cat Mode", systemImage: "cat") {
            MenuBarView()
                .environmentObject(catModeManager)
        }
        .menuBarExtraStyle(.window)
    }
}
