import SwiftUI

enum GamepadStyle {
    struct ColorStyle {
        let backgroundColor: Color
        let buttonColor: Color
    }
    
    case dmg
    case color(ColorStyle)
    
    func colors(forColorScheme colorScheme: ColorScheme) -> ColorStyle {
        switch self {
        case .dmg:
            .init(backgroundColor: .gameboy, buttonColor: .accent)
        case .color(let colors):
            colors
        }
    }
}
