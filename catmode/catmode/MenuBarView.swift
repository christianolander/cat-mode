import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var catModeManager: CatModeManager
    
    var body: some View {
        VStack {
            Button(action: {
                           // Toggle the Cat Mode state
                           catModeManager.toggleCatMode()
                       }) {
                           Text(catModeManager.isActive ? "Disable Cat Mode" : "Enable Cat Mode")
                       }
            
            Divider()
            
           
            Button("Settings"){
                NSApplication.shared.hide(nil)
                let environment = EnvironmentValues()
                    environment.openSettings()
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
               
            }
            
                
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal)
        }
        .frame(width: 200)
    }
}
