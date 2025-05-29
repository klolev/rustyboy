import SwiftUI

struct Cross: Shape {
    let percentage: CGFloat
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    
    init(percentage: CGFloat, innerRadius: CGFloat = 0, outerRadius: CGFloat = 0) {
        self.percentage = percentage
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
    }
    
    func path(in rect: CGRect) -> Path {
        let horizontal = (rect.width - rect.width * percentage) / 2
        let vertical = (rect.width - rect.width * percentage) / 2
        
        var path = Path()
        path.move(to: .init(x: rect.midX, y: 0))
        path.addArc(center: .init(x: rect.width - horizontal - outerRadius,
                                  y: outerRadius),
                    radius: outerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .zero,
                    clockwise: false)
        
        path.addArc(center: .init(x: rect.width - horizontal + innerRadius,
                                  y: vertical - innerRadius),
                    radius: innerRadius,
                    startAngle: .degrees(-180),
                    endAngle: .degrees(-270),
                    clockwise: true)
        
        path.addArc(center: .init(x: rect.width - outerRadius,
                                  y: vertical + outerRadius),
                    radius: outerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .zero,
                    clockwise: false)
        
        path.addArc(center: .init(x: rect.width - outerRadius,
                                  y: rect.width - vertical - outerRadius),
                    radius: outerRadius,
                    startAngle: .zero,
                    endAngle: .degrees(-270),
                    clockwise: false)
        
        path.addArc(center: .init(x: rect.width - horizontal + innerRadius,
                                  y: rect.width - vertical + innerRadius),
                    radius: innerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-180),
                    clockwise: true)
        
        path.addArc(center: .init(x: rect.width - horizontal - outerRadius,
                                  y: rect.width - outerRadius),
                    radius: outerRadius,
                    startAngle: .zero,
                    endAngle: .degrees(-270),
                    clockwise: false)
        
        path.addArc(center: .init(x: horizontal + outerRadius,
                                  y: rect.width - outerRadius),
                    radius: outerRadius,
                    startAngle: .degrees(-270),
                    endAngle: .degrees(-180),
                    clockwise: false)
        
        path.addArc(center: .init(x: horizontal - innerRadius,
                                  y: rect.width - vertical + innerRadius),
                    radius: innerRadius,
                    startAngle: .zero,
                    endAngle: .degrees(-90),
                    clockwise: true)
        
        path.addArc(center: .init(x: outerRadius,
                                  y: rect.width - vertical - outerRadius),
                    radius: outerRadius,
                    startAngle: .degrees(-270),
                    endAngle: .degrees(-180),
                    clockwise: false)
        
        path.addArc(center: .init(x: outerRadius,
                                  y: vertical + outerRadius),
                    radius: outerRadius,
                    startAngle: .degrees(-180),
                    endAngle: .degrees(-90),
                    clockwise: false)
        
        path.addArc(center: .init(x: horizontal - innerRadius,
                                  y: vertical - innerRadius),
                    radius: innerRadius,
                    startAngle: .degrees(-270),
                    endAngle: .zero,
                    clockwise: true)
        
        path.addArc(center: .init(x: horizontal + outerRadius,
                                  y: outerRadius),
                    radius: outerRadius,
                    startAngle: .degrees(-180),
                    endAngle: .degrees(-90),
                    clockwise: false)
        
        path.closeSubpath()
        
        return path
    }
}

struct DirectionalPadView: View {
    let didChangeDirection: (Direction?) -> Void
    
    private static let maxTiltAngle = Angle.degrees(10)
    
    @Environment(\.gamepadStyle)
    private var gamepadStyle
    
    @State
    private var position: CGPoint? = nil
    
    private var angle: Angle? {
        guard let position else { return nil }
        
        var angle = atan((abs(position.y - 0.5)) / (abs(position.x - 0.5)))
        
        if position.x < 0.5 && position.y < 0.5 {
            angle = (.pi - angle)
        } else if position.x < 0.5 {
            angle += .pi
        } else if position.y >= 0.5 {
            angle = (2 * .pi - angle)
        }
        
        return Angle(radians: angle)
    }
    
    private var direction: Direction? {
        angle.map { angle in
            Direction.allCases
                .first(where: { angle < $0.maxAngle }) ?? .right
        }
    }
    
    private var sectorProgression: CGFloat? {
        guard let direction, let angle else { return nil }
        
        var minAngle = direction.minAngle
        var maxAngle = direction.maxAngle
        if minAngle > maxAngle {
            if angle.radians < .pi {
                minAngle = -maxAngle
            } else {
                maxAngle = .radians(2 * .pi + maxAngle.radians)
            }
        }
        
        return (angle.radians - minAngle.radians) / (maxAngle.radians - minAngle.radians)
    }
    
    enum Direction: Int, CaseIterable {
        case right = 0
        case up = 1
        case left = 2
        case down = 3
        
        var maxAngle: Angle {
            Angle.radians(.pi / 4 + Double(rawValue) * 2 * .pi / 4)
        }
        
        var previous: Self {
            .init(rawValue: rawValue - 1) ?? .down
        }
        
        var minAngle: Angle {
            previous.maxAngle
        }
        
        var unitPoints: (UnitPoint, UnitPoint) {
            switch self {
            case .right:
                (.leading, .trailing)
            case .up:
                (.bottom, .top)
            case .left:
                (.trailing, .leading)
            case .down:
                (.top, .bottom)
            }
        }
    }
    
    private var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        switch direction {
        case .right, .left:
            return (0, 1, 0)
        case .up, .down:
            return (1, 0, 0)
        case nil:
            return (0, 0, 0)
        }
    }
    
    private var tiltAngle: Angle {
        switch direction {
        case .up, .right:
            Self.maxTiltAngle
        case .down, .left:
            -Self.maxTiltAngle
        case nil:
            .zero
        }
    }
    
    private func cross(percentage: CGFloat, geometry: GeometryProxy) -> Cross {
        Cross(percentage: percentage,
              innerRadius: geometry.size.width * 0.03,
              outerRadius: gamepadStyle.wrappedValue.isGBC ? geometry.size.width * 0.06 : geometry.size.width * 0.03)
    }
    
    private func arrow(geometry: GeometryProxy) -> some View {
        ZStack {
            Triangle()
                .fill(Color.white.opacity(0.1))
                .padding(geometry.size.width * 0.03)
                .offset(x: 1)
            
            Triangle()
                .fill(gamepadStyle.wrappedValue.dpadColor)
                .padding(geometry.size.width * 0.03)
            
            Triangle()
                .fill(Color.black.opacity(0.1))
                .padding(geometry.size.width * 0.03)
        }
    }
    
    private func grip(geom: GeometryProxy) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.white, .black.opacity(0.5)],
                                     startPoint: .top,
                                     endPoint: .bottom))
            
            RoundedRectangle(cornerRadius: 10)
                .padding(geom.size.width * 0.006)
        }
        .frame(height: geom.size.width * 0.08)
        .opacity(0.1)
    }
    
    private func hGrip(geom: GeometryProxy) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.white, .black.opacity(0.5)],
                                     startPoint: .top,
                                     endPoint: .bottom))
            
            RoundedRectangle(cornerRadius: 10)
                .padding(geom.size.width * 0.006)
        }
        .frame(width: geom.size.width * 0.08)
        .opacity(0.1)
    }
    
    var body: some View {
        GeometryReader { geom in
            ZStack {
                cross(percentage: 0.34, geometry: geom)
                    .fill(Color.black)
                
                ZStack {
                    cross(percentage: 0.34, geometry: geom)
                        .fill(gamepadStyle.wrappedValue.dpadColor)
                        .shadow(radius: 2)
                    
                    cross(percentage: 0.34, geometry: geom)
                        .fill(LinearGradient(colors: [.white, .black],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .opacity(0.15)
                    
                    cross(percentage: 0.30, geometry: geom)
                        .fill(gamepadStyle.wrappedValue.dpadColor)
                    
                    cross(percentage: 0.30, geometry: geom)
                        .fill(Color.white)
                        .padding(geom.size.width * 0.02)
                        .opacity(gamepadStyle.wrappedValue.isDMG ? 0.2 : 0.02)
                    
                    VStack(spacing: geom.size.width * 0.02) {
                        switch gamepadStyle.wrappedValue {
                        case .dmg:
                            grip(geom: geom)
                            grip(geom: geom)
                            grip(geom: geom)
                        case .color:
                            arrow(geometry: geom).rotationEffect(.degrees(180))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .frame(width: geom.size.width * 0.23)
                    .offset(y: geom.size.width * 0.32)
                    
                    VStack(spacing: geom.size.width * 0.02) {
                        switch gamepadStyle.wrappedValue {
                        case .dmg:
                            grip(geom: geom)
                            grip(geom: geom)
                            grip(geom: geom)
                        case .color:
                            arrow(geometry: geom)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .frame(width: geom.size.width * 0.23)
                    .offset(y: geom.size.width * -0.32)
                    
                    HStack(spacing: geom.size.width * 0.02) {
                        switch gamepadStyle.wrappedValue {
                        case .dmg:
                            hGrip(geom: geom)
                            hGrip(geom: geom)
                            hGrip(geom: geom)
                        case .color:
                            arrow(geometry: geom).rotationEffect(.degrees(-90))
                                .scaleEffect(y: -1)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .frame(height: geom.size.width * 0.23)
                    .offset(x: geom.size.width * -0.32)
                    
                    HStack(spacing: geom.size.width * 0.02) {
                        switch gamepadStyle.wrappedValue {
                        case .dmg:
                            hGrip(geom: geom)
                            hGrip(geom: geom)
                            hGrip(geom: geom)
                        case .color:
                            arrow(geometry: geom).rotationEffect(.degrees(90))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .frame(height: geom.size.width * 0.23)
                    .offset(x: geom.size.width * 0.32)
                    
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [.black, .black.opacity(0.2)],
                                                 center: .center,
                                                 startRadius: .zero,
                                                 endRadius: geom.size.width * 0.15))
                        
                        Circle()
                            .fill(.black)
                            .padding(geom.size.width * 0.03)
                            .opacity(0.1)
                    }
                    .opacity(0.3)
                    .frame(width: geom.size.width * 0.30,
                           height: geom.size.width * 0.30)
                }
                .padding(geom.size.width * 0.03)
                .rotation3DEffect(tiltAngle,
                                  axis: rotationAxis,
                                  anchor: .center,
                                  anchorZ: -10,
                                  perspective: 0.7)
                .mask {
                    LinearGradient(colors: [.black, position == nil ? .black : .black.opacity(0.85)],
                                   startPoint: direction?.unitPoints.0 ?? .top,
                                   endPoint: direction?.unitPoints.1 ?? .bottom)
                }
            }
            .animation(.easeOut(duration: 0.1), value: rotationAxis.x)
            .animation(.easeOut(duration: 0.1), value: rotationAxis.y)
            .animation(.easeOut(duration: 0.1), value: tiltAngle)
            .gesture(DragGesture(minimumDistance: .zero,
                                 coordinateSpace: .local)
                .onChanged { value in
                    position = CGPoint(x: value.location.x / geom.size.width,
                                       y: value.location.y / geom.size.width)
                }
                .onEnded { _ in
                    position = nil
                })
        }
        .onChange(of: direction) { _, new in
            didChangeDirection(new)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview("DMG") {
    DirectionalPadView(didChangeDirection: { print($0 as Any) })
        .environment(\.gamepadStyle, .constant(.dmg))
}

#Preview("GBC") {
    DirectionalPadView(didChangeDirection: { print($0 as Any) })
        .environment(\.gamepadStyle, .constant(.gbcRed))
}
