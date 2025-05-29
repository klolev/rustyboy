import SwiftUI
import RealityKit

struct GameListCellView: View {
    let name: String
    let image: Data?
    let didSelect: () -> Void
    let didTapDelete: () -> Void
    
    var body: some View {
//        VStack(spacing: 6) {
//            Image(.cartridge)
//                .resizable()
//                .frame(width: 160, height: 160)
//                .shadow(color: .black.opacity(0.3), radius: 3)
//                .ifLet(image) { view, image in
//                    view.overlay {
//                        Group {
//                            #if canImport(UIKit)
//                            let songArtwork: UIImage = UIImage(data: image) ?? UIImage()
//                            return Image(uiImage: songArtwork)
//                                .resizable()
//                            #elseif canImport(AppKit)
//                            let songArtwork: NSImage = NSImage(data: image) ?? NSImage()
//                            return Image(nsImage: songArtwork)
//                                .resizable()
//                            #endif
//                        }
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 110, height: 90, alignment: .bottomTrailing)
//                        .clipShape(RoundedRectangle(cornerRadius: 4))
//                        .offset(y: 12)
//                        .saturation(0.8)
//                    }
//                }
//            
//            Text(name)
//                .font(.semiBold(14))
//                .padding(.vertical, 8)
//        }
        RealityView { content in
            if let model = try? await ModelEntity(named: "cartridge") {
                content.add(model)
                model.position.z = -1
                model.scale = .one
                model.transform.rotation = .init(angle: .pi, axis: .init(0, 0, 1))
                    * .init(angle: -.pi / 16, axis: .init(1, 0, 0))
                    * .init(angle: -.pi / 16, axis: .init(0, 1, 0))
            }
            
            let light = DirectionalLight()
            light.transform.rotation = .init(angle: .pi / 4, axis: .init(0, 1, 0))
            content.add(light)
        } update: { content in
            guard let model = content.entities.first(where: { $0 is ModelEntity }) else {
                return
            }
            
            model.transform.rotation *= .init(angle: -.pi / 16, axis: .init(1, 0, 0))
        }
        .shadow(radius: 10)
        .frame(width: 160, height: 160)
        .contextMenu {
            Button(action: didSelect) {
                Text("play")
            }
            
            Button(action: didTapDelete) {
                Text("info")
            }
            
            Button(action: didTapDelete) {
                Text("delete")
            }
        }
        .onTapGesture(perform: didSelect)
    }
}
