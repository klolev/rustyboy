import SwiftUI

struct SettingsView: View {
    @Environment(\.screenFilter)
    private var isFilterEnabled
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink { GameGirlColorPicker() } label: {
                    Label {
                        Text("Appearance")
                            .font(.regular(18))
                    } icon: {
                        Image(systemName: "paintpalette")
                    }
                }
                
                Toggle(isOn: isFilterEnabled) {
                    Text("LCD Filter")
                        .font(.regular(18))
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
