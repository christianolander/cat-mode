  import SwiftUI
import MASShortcut

struct PreferencesView: View {
    @EnvironmentObject var catModeManager: CatModeManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Keyboard Shortcut")
                        .font(.headline)
                    
                    ShortcutRecorder(
                        shortcut: catModeManager.currentShortcut,
                        onChange: { newShortcut in
                            catModeManager.updateShortcut(newShortcut)
                        }
                    )
                    .frame(width: 200)
                }
                .padding()
            }
            
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    catModeManager.setLaunchAtLogin(enabled: newValue)
                }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 200)
    }
}
