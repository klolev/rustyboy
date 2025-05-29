import SwiftUI
import Slingshot

struct GamepadView: View {
    let didChangeDirection: (DirectionalPadView.Direction?) -> Void
    let didChangeHeldButtons: (ButtonSet) -> Void
    let didPressMenuButton: () -> Void
    
    struct ButtonSet: OptionSet {
        let rawValue: UInt8
        
        static let a = ButtonSet(rawValue: 1)
        static let b = ButtonSet(rawValue: 2)
        static let select = ButtonSet(rawValue: 4)
        static let start = ButtonSet(rawValue: 8)
    }
    
    @Environment(\.gamepadStyle)
    private var gamepadStyle
    
    @State
    private var heldButtons: ButtonSet = []
    
    init(didChangeDirection: @escaping (DirectionalPadView.Direction?) -> Void, 
         didChangeHeldButtons: @escaping (ButtonSet) -> Void,
         didPressMenuButton: @escaping () -> Void) {
        self.didChangeDirection = didChangeDirection
        self.didChangeHeldButtons = didChangeHeldButtons
        self.didPressMenuButton = didPressMenuButton
    }
    
    private func didChange(heldActionButtons: Set<ActionButtonsView.ActionButton>) {
        if heldActionButtons.contains(.a) {
            heldButtons.insert(.a)
        } else {
            heldButtons.remove(.a)
        }
        
        if heldActionButtons.contains(.b) {
            heldButtons.insert(.b)
        } else {
            heldButtons.remove(.b)
        }
    }
    
    private func gameGirlText(geom: GeometryProxy) -> some View {
        Text("Game Girl".uppercased())
            .kerning(-geom.size.width * 0.0025)
            .font(.semiBoldItalic(32))
    }
    
    private func gbcHeader(geom: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: geom.size.width * 0.03) {
            Spacer()
            gameGirlText(geom: geom)
                .foregroundStyle(.white.opacity(0.7))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
            
            HStack(spacing: -geom.size.width * 0.012) {
                Text("C")
                    .foregroundStyle(GamepadStyle.gbcRed.colors(forColorScheme: .dark).backgroundColor)
                
                Text("O")
                    .foregroundStyle(GamepadStyle.gbcBlurble.colors(forColorScheme: .dark).backgroundColor)
                    .rotationEffect(.degrees(-10))
                    .scaleEffect(x: 0.8, y: 0.7)
                    .offset(y: geom.size.width * 0.005)
                
                Text("L")
                    .foregroundStyle(GamepadStyle.gbcBrat.colors(forColorScheme: .dark).backgroundColor)
                    .rotationEffect(.degrees(-10))
                
                Text("O")
                    .foregroundStyle(GamepadStyle.gbcDaria.colors(forColorScheme: .dark).backgroundColor)
                    .offset(x: -geom.size.width * 0.01, y: geom.size.width * 0.005)
                    .scaleEffect(x: 0.8, y: 0.7)
                    .rotationEffect(.degrees(-10))
                
                Text("R")
                    .foregroundStyle(GamepadStyle.gbcFunnyBlue.colors(forColorScheme: .dark).backgroundColor)
                    .offset(x: -geom.size.width * 0.01)
            }
            .font(.custom("ChalkboardSE-Bold", size: 32))
            .minimumScaleFactor(0.1)
            .offset(y: -geom.size.width * 0.01)
            Spacer()
        }
        .padding(.vertical, geom.size.width * 0.02)
        .frame(height: geom.size.width * 0.15)
        .background {
            ZStack {
                Color.black.opacity(0.1)
                    .frame(width: geom.size.width * 6,
                           height: geom.size.width * 3)
                    .clipShape(Ellipse())
                    .offset(x: -5, y: -geom.size.width * 1.5 + geom.size.width * 0.075)
                
                Color.white.opacity(0.3)
                    .frame(width: geom.size.width * 6,
                           height: geom.size.width * 3)
                    .clipShape(Ellipse())
                    .offset(x: -5, y: -geom.size.width * 1.5 + geom.size.width * 0.075 - 1)
                
                Color.black
                    .frame(width: geom.size.width * 6,
                           height: geom.size.width * 3)
                    .clipShape(Ellipse())
                    .offset(y: -geom.size.width * 1.5 + geom.size.width * 0.075 - 2)
            }
        }
        .clipped()
    }
    
    private func dmgHeader(geom: GeometryProxy) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("Nottendo")
                .kerning(-1)
                .font(.system(size: 14, weight: .bold))
                .scaleEffect(y: 0.9)
            gameGirlText(geom: geom)
            Spacer()
        }
        .padding()
        .foregroundStyle(.logo)
    }
    
    var body: some View {
        GeometryReader { geom in
            VStack(spacing: 0) {
                if gamepadStyle.wrappedValue.isGBC {
                    gbcHeader(geom: geom)
                } else {
                    dmgHeader(geom: geom)
                }
                
                Spacer()
                
                VStack(spacing: geom.size.width * 0.1) {
                    HStack(alignment: .center, spacing: 0) {
                        DirectionalPadView(didChangeDirection: didChangeDirection)
                            .frame(width: geom.size.width / 2.5,
                                   height: geom.size.width / 2.5)
                            .offset(x: geom.size.width * 0.05)
                        
                        Spacer()
                        
                        ActionButtonsView(didChangeHeldActionButtons: didChange(heldActionButtons:))
                            .frame(width: geom.size.width / 2.5,
                                   height: geom.size.width / 3)
                            .offset(y: geom.size.width * 0.05)
                    }
                    
                    HStack(spacing: geom.size.width * 0.05) {
                        StartSelectButton(name: "Select",
                                          didChangeHoldStatus: {
                            if $0 {
                                heldButtons.insert(.select)
                            } else {
                                heldButtons.remove(.select)
                            }
                        })
                        .frame(width: geom.size.width * 0.15)
                        
                        StartSelectButton(name: "Start",
                                          didChangeHoldStatus: {
                            if $0 {
                                heldButtons.insert(.start)
                            } else {
                                heldButtons.remove(.start)
                            }
                        })
                        .frame(width: geom.size.width * 0.15)
                    }
                    
                    Button(action: didPressMenuButton) {
                        Image(systemName: "ellipsis.circle.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: geom.size.width * 0.1, height: geom.size.width * 0.1)
                            .foregroundStyle(gamepadStyle.wrappedValue.actionButtonColor)
                            .opacity(0.7)
                    }
                    .padding(.bottom, geom.size.width * 0.05)
                }
                .onChange(of: heldButtons) {
                    didChangeHeldButtons($1)
                }
            }
        }
        .if(gamepadStyle.wrappedValue.isGBC) {
            $0.environment(\.colorScheme, .dark)
        }
    }
}

#Preview("DMG") {
    VStack(spacing: 0) {
        Color.black.opacity(0.8)
            .aspectRatio(.screenWidth / .screenHeight, contentMode: .fit)
        GamepadView(didChangeDirection: { _ in },
                    didChangeHeldButtons: { _ in },
                    didPressMenuButton: {})
        .environment(\.gamepadStyle, .constant(.dmg))
    }
    .background {
        GamepadStyle.dmg.background(forColorScheme: .dark)
    }
}

#Preview("GBC") {
    VStack(spacing: 0) {
        Color.black.opacity(0.8)
            .aspectRatio(.screenWidth / .screenHeight, contentMode: .fit)
        GamepadView(didChangeDirection: { _ in },
                    didChangeHeldButtons: { _ in },
                    didPressMenuButton: {})
        .environment(\.gamepadStyle, .constant(.gbcRed))
//        .frame(width: 100)
    }
    .background {
        GamepadStyle.gbcRed.background(forColorScheme: .dark)
    }
}
