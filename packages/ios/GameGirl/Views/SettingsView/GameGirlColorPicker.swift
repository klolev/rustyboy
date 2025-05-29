import SwiftUI

struct GameGirlColorPicker: View {
    private static let colors: [GamepadStyle] = [.gbcRed, .gbcDaria, .gbcBrat, .gbcBlurble, .gbcFunnyBlue, .gbcHottie]
    
    @Environment(\.gamepadStyle)
    private var gamepadStyle
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @Environment(\.self)
    private var environment
    
    private func cell(for style: GamepadStyle, colorScheme: ColorScheme) -> some View {
        VStack(spacing: 0) {
            Color.black
                .aspectRatio(.screenWidth / .screenHeight, contentMode: .fit)
            
            GamepadView(didChangeDirection: { _ in },
                        didChangeHeldButtons: { _ in },
                        didPressMenuButton: {})
            .environment(\.gamepadStyle, .constant(style))
            .disabled(true)
            .environment(\.colorScheme, colorScheme)
        }
        .background {
            style.background(forColorScheme: colorScheme)
        }
        .frame(width: 150, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
    }
    
    private func selectableCell(for style: GamepadStyle, colorScheme: ColorScheme) -> some View {
        let isSelected = gamepadStyle.wrappedValue.rawValue(in: environment) == style.rawValue(in: environment)
        
        return VStack(spacing: 16) {
            cell(for: style, colorScheme: colorScheme)
            
            Circle()
                .stroke(isSelected ? .accent : Color.secondary, style: StrokeStyle(lineWidth: 1))
                .if(isSelected) {
                    $0.fill(.accent)
                        .overlay {
                            Image(systemName: "checkmark")
                                .resizable()
                                .padding(7)
                                .foregroundStyle(colorScheme == .dark ? .black : .white)
                        }
                }
        }
        .padding(.vertical)
        .onTapGesture {
            gamepadStyle.wrappedValue = style
        }
    }
    
    var body: some View {
        List {
            VStack(alignment: .center) {
                Text("Selected style")
                    .font(.semiBold(32))
                
                cell(for: gamepadStyle.wrappedValue, colorScheme: .dark)
                    .padding(.bottom)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        selectableCell(for: .dmg, colorScheme: .light)
                        selectableCell(for: .dmg, colorScheme: .dark)
                    }
                }
            } header: {
                Text("Gameboy")
                    .font(.semiBold(16))
            }
            
            Section {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(Self.colors.enumerated()), id: \.offset) { (index, color) in
                            selectableCell(for: color, colorScheme: .dark)
                        }
                    }
                }
            } header: {
                Text("Gameboy Color")
                    .font(.semiBold(16))
            }
        }
        .navigationTitle("Appearance")
    }
}

#Preview {
    GameGirlColorPicker()
}
