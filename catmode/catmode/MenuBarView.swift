import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var catModeManager: CatModeManager
    
    var body: some View {
        VStack {
            Toggle("Cat Mode", isOn: Binding(
                get: { catModeManager.isActive },
                set: { _ in catModeManager.toggleCatMode() }
            ))
            .toggleStyle(.switch)
            .padding()
            
            Divider()
            
            SettingsLink {
                Text("Preferences...")
            }
            .padding(.horizontal)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal)
        }
        .frame(width: 200)
    }
}
