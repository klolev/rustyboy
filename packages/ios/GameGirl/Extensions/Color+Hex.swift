import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 0xFF,
                  green: Double((hex >> 8) & 0xFF) / 0xFF,
                  blue: Double(hex & 0xFF) / 0xFF)
    }
    
    func resolve(toHexIn values: EnvironmentValues) -> UInt32 {
        let resolved = resolve(in: values)

        return UInt32(resolved.red * 0xFF) << 16
        | UInt32(resolved.green * 0xFF) << 8
        | UInt32(resolved.blue * 0xFF)
    }
}
