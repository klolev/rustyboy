import SwiftUI
import Slingshot

struct ActionButtonsView: View {
    let didChangeHeldActionButtons: (Set<ActionButton>) -> Void
    
    private let buttonWidthMultiplier = 0.4
    
    enum ActionButton {
        case a, b
    }
    
    @State
    private var heldButtons: Set<ActionButton> = []
    
    @State
    private var firstHeldButton: ActionButton?
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @Environment(\.gamepadStyle)
    private var gamepadStyle
    
    private var color: Color {
        gamepadStyle.wrappedValue.actionButtonColor
    }
    
    private func button(name: String, action: ActionButton, geom: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            let held = heldButtons.contains(action)
            ZStack {
                Circle()
                    .fill(.black)
                
                ZStack {
                    Circle()
                        .fill(color)
                        .shadow(radius: 4)
                    
                    Circle()
                        .fill(LinearGradient(colors: [.white, .black],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .opacity(0.15)
                    
                    Circle()
                        .fill(color)
                        .padding(geom.size.width * buttonWidthMultiplier * 0.07)
                    
                    if gamepadStyle.wrappedValue.areLabelsInsideActionButtons {
                        ZStack {
                            Text(name)
                                .font(.system(size: 90, weight: .bold))
                                .minimumScaleFactor(0.001)
                                .foregroundStyle(.white.opacity(0.2))
                                .offset(x: 2)
                            
                            Text(name)
                                .font(.system(size: 90, weight: .bold))
                                .minimumScaleFactor(0.001)
                                .foregroundStyle(color)
                            
                            Text(name)
                                .font(.system(size: 90, weight: .bold))
                                .minimumScaleFactor(0.001)
                                .foregroundStyle(.black.opacity(0.4))
                        }
                        .frame(width: geom.size.width * (buttonWidthMultiplier - 0.20),
                               height: geom.size.width * (buttonWidthMultiplier - 0.17),
                               alignment: .bottomLeading)
                        .scaleEffect(x: 0.9, y: 1.4)
                        .offset(y: geom.size.width * 0.02)
                        .rotationEffect(.degrees(20))
                    }
                }
                .opacity(held ? 0.6 : 1)
                .scaleEffect(.init(width: held ? 0.85 : 1,
                                   height: held ? 0.85 : 1))
            }
            .animation(.easeOut(duration: 0.1), value: held)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: geom.size.width * buttonWidthMultiplier)
            
            if !gamepadStyle.wrappedValue.areLabelsInsideActionButtons {
                Text(name)
                    .font(.semiBold(22))
                    .foregroundStyle(.logo)
                    .scaleEffect(y: 0.8)
            }
        }
    }
    
    private func button(at position: CGPoint, in geometry: GeometryProxy) -> ActionButton? {
        let buttonWidth = geometry.size.width * buttonWidthMultiplier
        
        guard position.y < buttonWidth else { return nil }
        
        if position.x < buttonWidth {
            return .b
        } else if position.x > buttonWidth + geometry.size.width * 0.05 {
            return .a
        }
        
        return nil
    }
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                if case .dmg = gamepadStyle.wrappedValue {
                    RoundedRectangle(cornerRadius: (geom.size.width * buttonWidthMultiplier + geom.size.width * 0.05) / 2)
                        .fill(LinearGradient(colors: [.black, .black.opacity(0.3)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .frame(width: geom.size.width * buttonWidthMultiplier * 2 + geom.size.width * 0.1,
                               height: geom.size.width * buttonWidthMultiplier + geom.size.width * 0.05)
                        .offset(y: !gamepadStyle.wrappedValue.areLabelsInsideActionButtons ? -geom.size.width * 0.05 : 0)
                        .opacity(0.1)
                }
                
                HStack(spacing: geom.size.width * 0.1) {
                    button(name: "B", action: .b, geom: geom)
                    button(name: "A", action: .a, geom: geom)
                    Spacer()
                }
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let button = button(at: value.location, in: geom)
                        if let button, firstHeldButton == nil {
                            firstHeldButton = button
                            heldButtons.insert(button)
                        } else if let firstHeldButton, button == firstHeldButton || button == nil {
                            heldButtons = [firstHeldButton]
                        } else if let firstHeldButton, let button, button != firstHeldButton {
                            heldButtons.insert(button)
                        }
                    }
                    .onEnded { _ in
                        firstHeldButton = nil
                        heldButtons = []
                    })
            }
            .rotationEffect(.degrees(-20))
            .onChange(of: heldButtons) { didChangeHeldActionButtons($1) }
        }
    }
}

#Preview("DMG") {
    ActionButtonsView(didChangeHeldActionButtons: { _ in })
        .environment(\.gamepadStyle, .constant(.dmg))
}

#Preview("GBC") {
    ActionButtonsView(didChangeHeldActionButtons: { _ in })
        .environment(\.gamepadStyle, .constant(.gbcRed))
}
