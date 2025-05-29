import SwiftUI

struct StartSelectButton: View {
    let name: String
    let didChangeHoldStatus: (Bool) -> Void
    
    @State
    private var isHolding = false
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @Environment(\.gamepadStyle)
    private var gamepadStyle
    
    @ViewBuilder
    private var label: some View {
        switch gamepadStyle.wrappedValue {
        case .dmg:
            Text(name.uppercased())
                .font(.semiBold(16))
                .foregroundStyle(.logo)
                .scaleEffect(y: 0.8)
        case .color:
            ZStack {
                Text(name.uppercased())
                    .foregroundStyle(.black.opacity(0.1))
                    .offset(x: -1)
                
                Text(name.uppercased())
                    .foregroundStyle(gamepadStyle.wrappedValue.colors(forColorScheme: colorScheme).backgroundColor)
                
                Text(name.uppercased())
                    .foregroundStyle(.white.opacity(0.3))
            }
            .font(.custom("AppleSDGothicNeo-Thin", size: 20))
            .opacity(0.5)
        }
    }
    
    private var shape: AnyShape {
        switch gamepadStyle.wrappedValue {
        case .dmg:
            .init(RoundedRectangle(cornerRadius: 16))
        case .color:
            .init(RoundedRectangle(cornerRadius: 30))
        }
    }
    
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                shape
                    .fill(LinearGradient(colors: [.black, .black.opacity(0.1)],
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .opacity(gamepadStyle.wrappedValue.isDMG ? 0.1 : 0.3)
                
                shape
                    .fill(.black)
                    .padding(gamepadStyle.wrappedValue.isDMG ? 3 : 4)
                
                ZStack {
                    shape
                        .fill(gamepadStyle.wrappedValue.startSelectButtonColor)
                        .padding(gamepadStyle.wrappedValue.isDMG ? 4 : 5)
                    
                    shape
                        .fill(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .padding(gamepadStyle.wrappedValue.isDMG ? 4 : 5)
                        .opacity(gamepadStyle.wrappedValue.isDMG ? 1 : 0.5)
                }
                .opacity(isHolding ? 0.9 : 1)
                .scaleEffect(.init(width: isHolding ? 0.95 : 1,
                                   height: isHolding ? 0.80 : 1))
            }
            .animation(.easeOut(duration: 0.1), value: isHolding)
            .aspectRatio(gamepadStyle.wrappedValue.isDMG ? 4 : 3, contentMode: .fit)
            
            label
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { _ in isHolding = true }
            .onEnded { _ in isHolding = false })
        .rotationEffect(gamepadStyle.wrappedValue.startSelectButtonAngle)
        .onChange(of: isHolding) { didChangeHoldStatus($1) }
    }
}

#Preview("DMG") {
    StartSelectButton(name: "Start", didChangeHoldStatus: { _ in })
        .environment(\.gamepadStyle, .constant(.dmg))
}

#Preview("GBC") {
    StartSelectButton(name: "Start", didChangeHoldStatus: { _ in })
        .environment(\.gamepadStyle, .constant(.gbcRed))
        .background(GamepadStyle.gbcRed.colors(forColorScheme: .dark).backgroundColor)
}
