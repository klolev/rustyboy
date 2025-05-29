import SwiftUI
import SwiftData
import GameGirlCoreBindings
import Charts

struct GameView: View {
    @Environment(\.modelContext)
    private var modelContext
    
    @Environment(\.scenePhase)
    private var scenePhase
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @Environment(\.gamepadStyle)
    private var gamepadStyle
    
    @State
    private var gameboy: GameGirlGameboy?
    
    @State
    private var viewModel: GameViewModel
    
    private var dismiss: () -> Void
    
    init(viewModel: GameViewModel,
         dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
        self._viewModel = .init(initialValue: viewModel)
    }
    
    private func didPressMenuButton() {
        guard let gameboy else { return }
        
        withAnimation {
            viewModel.pause(withGameboy: gameboy)
        }
    }
    
    private func on(gameMenuInput input: GameMenuView.Input) {
        guard let gameboy else { return }
        
        switch input {
        case .didTapPeer:
            return // kek
        case .didTapSavestate(let savestate):
            let result = viewModel.load(savestate: savestate, withGameboy: gameboy)
            if let failure = result.failure {
                print(failure)
            }
        case .didTapReset:
            viewModel.reset(gameboy: gameboy)
        case .didTapSave:
            if let savestate = viewModel.save(gameboy: gameboy) {
                modelContext.insert(savestate)
            }
        case .didTapDismiss:
            withAnimation {
                viewModel.resume()
            }
        case .didTapExit:
            dismiss()
        }
    }
    
    #if FALSE
    struct Point<T>: Identifiable {
        var id: Date { date }
        
        let date: Date
        let x: T
    }
    
    @State
    private var audioDebuggingBuffer: [Point<AudioDebugging>] = []
    
    private func audioDebugView(audioDebugging: AudioDebugging) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Sound enabled: \(audioDebugging.soundEnabled)")
                    .foregroundStyle(Color.red)
                    .shadow(radius: 0.2)
                
                Text("L: \(audioDebugging.masterVolumeLeft)")
                    .foregroundStyle(Color.red)
                    .shadow(radius: 0.2)
                
                Text("R: \(audioDebugging.masterVolumeRight)")
                    .foregroundStyle(Color.red)
                    .shadow(radius: 0.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
//            channelDebugView(channelDebugging: audioDebuggingBuffer.map { Point(date: $0.date, x: $0.x.channel1.output) })
//                .frame(maxWidth: .infinity, alignment: .leading)
            channelDebugView(channelDebugging: audioDebuggingBuffer.map { Point(date: $0.date, x: $0.x.channel2) })
                .frame(maxWidth: .infinity, alignment: .leading)
//            channelDebugView(channelDebugging: audioDebuggingBuffer.map { Point(date: $0.date, x: $0.x.channel3.output) })
//                .frame(maxWidth: .infinity, alignment: .leading)
//            channelDebugView(channelDebugging: audioDebuggingBuffer.map { Point(date: $0.date, x: $0.x.channel4.output) })
//                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 500)
        .background(Material.regular)
        .onChange(of: audioDebugging) {
            let now = Date()
            self.audioDebuggingBuffer.append(.init(date: now, x: audioDebugging))
            if audioDebuggingBuffer.count >= 56 {
                _ = audioDebuggingBuffer.removeFirst()
            }
        }
    }
    
    private func channelDebugView(channelDebugging: [Point<AudioChannelDebugging>]) -> some View {
        Chart(channelDebugging) { point in
            LineMark(x: .value("t", point.date),
                     y: .value("a", point.x.output))
        }
        .chartYVisibleDomain(length: 2)
    }
    #endif
    
    var body: some View {
        Group {
            if let pauseScreen = viewModel.pauseScreen {
                GameMenuView(sendInput: on(gameMenuInput:), game: viewModel.game)
                    .transition(.move(edge: .bottom))
            } else {
                VStack(spacing: 0) {
                    if gameboy != nil {
                        ScreenView(viewModel: viewModel)
                            .aspectRatio(.screenWidth / .screenHeight, contentMode: .fit)
                            #if FALSE
                            .overlay {
                                if let audioDebugging = viewModel.audioDebugging {
                                    audioDebugView(audioDebugging: audioDebugging)
                                }
                            }
                            #endif
                    }
                    
                    #if os(iOS)
                    GamepadView(didChangeDirection: viewModel.didChange(direction:),
                                didChangeHeldButtons: viewModel.didChange(heldButtons:),
                                didPressMenuButton: didPressMenuButton)
                    #endif
                }
                .background {
                    gamepadStyle.wrappedValue.background(forColorScheme: colorScheme)
                }
            }
        }
        .onAppear {
            switch viewModel.start() {
            case .success(let gameboy):
                self.gameboy = gameboy
            case .failure(let error):
                print(error)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                if let gameboy {
                    viewModel.pause(withGameboy: gameboy)
                }
            }
        }
        .modifier(KeyBindingsModifier(didChangeDirection: viewModel.didChange(direction:),
                                      didChangeHeldButtons: viewModel.didChange(heldButtons:)))
    }
}
