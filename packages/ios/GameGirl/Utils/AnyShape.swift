import SwiftUI

public struct AnyShape: Shape {
    public let makePath: @Sendable (CGRect) -> Path

    public init(makePath: @Sendable @escaping (CGRect) -> Path) {
        self.makePath = makePath
    }

    public init<Wrapped: Shape>(_ shape: Wrapped) {
        self.makePath = { shape.path(in: $0) }
    }

    public func path(in rect: CGRect) -> Path {
        return makePath(rect)
    }
}
