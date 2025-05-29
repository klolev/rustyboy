import SwiftUI

fileprivate struct GamepadStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: Binding<GamepadStyle> = .constant(.gbcRed)
}

extension EnvironmentValues {
    var gamepadStyle: Binding<GamepadStyle> {
        get { self[GamepadStyleEnvironmentKey.self] }
        set { self[GamepadStyleEnvironmentKey.self] = newValue }
    }
}
