import SwiftUI
import OrderedCollections

struct KeyBindingsModifier: ViewModifier {
    let didChangeDirection: (DirectionalPadView.Direction?) -> Void
    let didChangeHeldButtons: (GamepadView.ButtonSet) -> Void
    
    private static let directionKeyBindings: [KeyEquivalent: DirectionalPadView.Direction] = [
        .leftArrow: .left,
        .rightArrow: .right,
        .downArrow: .down,
        .upArrow: .up
    ]
    
    private static let actionKeyBindings: [KeyEquivalent: GamepadView.ButtonSet.Element] = [
        .init("z"): .a,
        .init("x"): .b,
        .return: .start,
        .space: .select
    ]
    
    @State
    private var heldButtons: GamepadView.ButtonSet = []
    
    @State
    private var heldDirections: OrderedSet<DirectionalPadView.Direction> = []
    
    @FocusState
    private var focused: Bool
    
    func body(content: Content) -> some View {
        content
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.up, .down, .repeat]) { keyPress in
            if let action = Self.actionKeyBindings[keyPress.key] {
                if keyPress.phase == .up {
                    heldButtons.remove(action)
                } else {
                    heldButtons.insert(action)
                }
                
                return .handled
            } else if let direction = Self.directionKeyBindings[keyPress.key] {
                if keyPress.phase == .up {
                    heldDirections.remove(direction)
                } else {
                    heldDirections.append(direction)
                }
                
                return .handled
            } else {
                return .ignored
            }
        }
        .onChange(of: heldButtons) { old, new in
            didChangeHeldButtons(new)
        }
        .onChange(of: heldDirections) { old, new in
            didChangeDirection(new.first)
        }
    }
}
