import SwiftUI

enum GamepadStyle {
    struct ColorStyle {
        let backgroundColor: Color
    }
    
    case dmg
    case color(ColorStyle)
    
    init?(rawValue: String) {
        switch rawValue {
        case "dmg":
            self = .dmg
        default:
            guard let value = UInt32(rawValue) else {
                return nil
            }
            self = .color(.init(backgroundColor: Color(hex: value)))
        }
    }
    
    func rawValue(in environmentValues: EnvironmentValues) -> String {
        switch self {
        case .dmg:
            "dmg"
        case .color(let colorStyle):
            "\(colorStyle.backgroundColor.resolve(toHexIn: environmentValues))"
        }
    }
    
    var isDMG: Bool {
        switch self {
        case .dmg: true
        case .color: false
        }
    }
    
    var isGBC: Bool {
        switch self {
        case .color: true
        case .dmg: false
        }
    }
    
    static var gbcRed: GamepadStyle {
        .color(.init(backgroundColor: .init(hex: 0xD43D59)))
    }
    
    static var gbcDaria: GamepadStyle {
        .color(.init(backgroundColor: .init(hex: 0xEACD45)))
    }
    
    static var gbcBrat: GamepadStyle {
        .color(.init(backgroundColor: .init(hex: 0x8ECC2B)))
    }
    
    static var gbcFunnyBlue: GamepadStyle {
        .color(.init(backgroundColor: .init(hex: 0x1F85AF)))
    }
    
    static var gbcBlurble: GamepadStyle {
        .color(.init(backgroundColor: .init(hex: 0x3B3F97)))
    }
    
    static var gbcHottie: GamepadStyle {
        .color(.init(backgroundColor: .init(hex: 0xE551E2)))
    }

    func colors(forColorScheme colorScheme: ColorScheme) -> ColorStyle {
        switch self {
        case .dmg:
            .init(backgroundColor: .gameboy)
        case .color(let colors):
            colors
        }
    }
    
    var actionButtonColor: Color {
        switch self {
        case .dmg: .accent
        case .color: .init(hex: 0x1F2436)
        }
    }
    
    var dpadColor: Color {
        switch self {
        case .dmg: .dpad
        case .color: .init(hex: 0x1F2436)
        }
    }
    
    var startSelectButtonColor: Color {
        switch self {
        case .dmg: .gray
        case .color: .init(hex: 0x1F2436)
        }
    }
    
    var startSelectButtonAngle: Angle {
        switch self {
        case .color: .zero
        case .dmg: .radians(-.pi / 8)
        }
    }
    
    var areLabelsInsideActionButtons: Bool {
        switch self {
        case .dmg: false
        case .color: true
        }
    }
    
    @ViewBuilder
    func background(forColorScheme colorScheme: ColorScheme) -> some View {
        switch self {
        case .dmg:
            ZStack {
                colors(forColorScheme: colorScheme).backgroundColor
                
                LinearGradient(colors: [.clear, .black.opacity(0.05)],
                               startPoint: .top,
                               endPoint: .bottom)
                
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 10) {
                                ForEach(0..<7) { i in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.white)
                                            .opacity(0.2)
                                            .offset(x: 1, y: 1)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.black)
                                            .opacity(0.2)
                                            .offset(x: 1, y: -1)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.black)
                                    }
                                    .frame(width: 7)
                                }
                            }
                            .frame(height: 80)
                            .background {
                                LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.2)],
                                               startPoint: .top,
                                               endPoint: .bottom)
                                .offset(y: 50)
                                .frame(width: 420)
                            }
                            .rotationEffect(.degrees(-25))
                            .padding()
                        }
                    }
                }
            }
            .ignoresSafeArea()
        case .color(let colors):
            ZStack {
                Color.black
                    .ignoresSafeArea(edges: .top)
                
                GeometryReader { geometry in
                    ZStack {
                        colors.backgroundColor
                        
                        LinearGradient(colors: [.black.opacity(0.03), .black.opacity(0.02)],
                                       startPoint: .bottom,
                                       endPoint: .top)
                        
                        colors.backgroundColor
                            .clipShape(RoundedRectangle(cornerRadius: geometry.size.width * 0.15))
                            .padding(geometry.size.width * 0.15)
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
                
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            let size = geometry.size.width * 0.016
                            
                            Grid(horizontalSpacing: size, verticalSpacing: size) {
                                ForEach(0..<8) { j in
                                    GridRow {
                                        ForEach(0..<8) { i in
                                            Circle()
                                                .fill(.black)
                                                .frame(width: size)
                                                .opacity((i == 0 || i == 7) && (j == 0 || j == 7) ? 0 : ((i + j) % 2 == 0 ? 0.2 : 1))
                                        }
                                    }
                                }
                            }
                            .transformEffect(.init(1, -0.15, 0, 1, 0, 0))
                            .padding(.horizontal, geometry.size.width * 0.05)
                        }
                    }
                }
            }
        }
    }
}
