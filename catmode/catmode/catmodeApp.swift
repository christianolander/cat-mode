import SwiftUI

@main
struct CatModeApp: App {
    @StateObject private var catModeManager = CatModeManager()
    
    var body: some Scene {
        MenuBarExtra("Cat Mode", systemImage: "cat") {
            MenuBarView()
                .environmentObject(catModeManager)
        }
        .menuBarExtraStyle(.automatic)
        
        Settings {
            PreferencesView()
                .environmentObject(catModeManager)
        }
    }
}
