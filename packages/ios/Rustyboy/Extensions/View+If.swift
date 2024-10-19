import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content>(_ condition: Bool,
                       @ViewBuilder content: (Self) -> Content) -> some View  where Content: View {
        if condition {
            content(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifLet<Value, Content>(_ value: Value?,
                               @ViewBuilder content: (Self, Value) -> Content) -> some View  where Content: View {
        if let value {
            content(self, value)
        } else {
            self
        }
    }
}
