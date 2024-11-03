import SwiftUI

struct GameListCellView: View {
    let name: String
    let image: Data?
    let didSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Image(.cartridge)
                .resizable()
                .frame(width: 160, height: 160)
                .shadow(color: .black.opacity(0.3), radius: 3)
                .ifLet(image) { view, image in
                    view.overlay {
                        Group {
                            #if canImport(UIKit)
                            let songArtwork: UIImage = UIImage(data: image) ?? UIImage()
                            return Image(uiImage: songArtwork)
                                .resizable()
                            #elseif canImport(AppKit)
                            let songArtwork: NSImage = NSImage(data: image) ?? NSImage()
                            return Image(nsImage: songArtwork)
                                .resizable()
                            #endif
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 90, alignment: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .offset(y: 12)
                        .saturation(0.8)
                    }
                }
            
            Text(name)
                .font(.semiBold(14))
                .padding(.vertical, 8)
        }
        .contextMenu {
            Button(action: didSelect) {
                Text("play")
            }
            Button(action: didSelect) {
                Text("delete")
            }
        }
        .onTapGesture(perform: didSelect)
    }
}
