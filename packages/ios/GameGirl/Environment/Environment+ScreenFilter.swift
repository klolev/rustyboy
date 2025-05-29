import SwiftUI

fileprivate struct ScreenFilterEnvironmentKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

extension EnvironmentValues {
    public var screenFilter: Binding<Bool> {
        get { self[ScreenFilterEnvironmentKey.self] }
        set { self[ScreenFilterEnvironmentKey.self] = newValue }
    }
}
