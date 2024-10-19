import Foundation
import MetalKit
import SwiftUI
import RustyboyCoreBindings

struct ScreenView: ViewRepresentable {
    #if canImport(AppKit)
    typealias NSViewType = MTKView
    #else
    typealias UIViewType = MTKView
    #endif
    
    let viewModel: GameViewModel
    private let device = MTLCreateSystemDefaultDevice()!

    func makeCoordinator() -> MTKViewDelegate {
        ScreenRenderer(device: device, viewModel: viewModel)!
    }

    func makeView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = device
        mtkView.colorPixelFormat = .bgra8Unorm
        #if canImport(UIKit)
        mtkView.isOpaque = true
        #endif
        mtkView.preferredFramesPerSecond = 60
        mtkView.delegate = context.coordinator
        mtkView.autoResizeDrawable = true
        mtkView.drawableSize = mtkView.frame.size

        return mtkView
    }

    func updateView(_ view: MTKView, context: Context) {}
}

//#Preview {
//    ScreenView(render: {
//        Data(repeating: 0xFF,
//             count: .screenWidth * .screenHeight * 4)
//    })
//    .aspectRatio(.screenWidth / .screenHeight, contentMode: .fit)
//    .background(Color.black)
//}
