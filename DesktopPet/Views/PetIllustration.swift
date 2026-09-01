import CoreGraphics
import ImageIO
import SwiftUI

/// The pixel-art pets that reminders rotate through. Each ships as a 4-frame
/// horizontal sprite sheet in the app bundle; the sheet is sliced once and the
/// frames are cycled to animate a walk.
enum PetKind: String, CaseIterable, Sendable {
    case greyCat
    case orangeCat
    case blackCat
    case hamster

    /// Resource name of the sprite sheet in the bundle.
    var assetName: String {
        switch self {
        case .greyCat: return "grey-cat"
        case .orangeCat: return "orange-cat"
        case .blackCat: return "black-cat"
        case .hamster: return "hamster"
        }
    }
}

/// Loads and caches the sliced frames for each pet's sprite sheet.
private enum SpriteCache {
    static let frameCount = 4
    private static var cache: [PetKind: [CGImage]] = [:]

    static func frames(for kind: PetKind) -> [CGImage] {
        if let cached = cache[kind] { return cached }
        let sliced = load(kind.assetName)
        cache[kind] = sliced
        return sliced
    }

    private static func load(_ name: String) -> [CGImage] {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png"),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return [] }

        let frameWidth = sheet.width / frameCount
        let frameHeight = sheet.height
        return (0..<frameCount).compactMap { index in
            sheet.cropping(to: CGRect(
                x: index * frameWidth, y: 0, width: frameWidth, height: frameHeight
            ))
        }
    }
}

struct PetIllustration: View {
    var kind: PetKind
    var isCallingAttention: Bool = false
    /// Sprites are drawn facing right; flip when the pet travels right-to-left.
    var facingLeft: Bool = false

    private static let framesPerSecond = 7.0

    var body: some View {
        let frames = SpriteCache.frames(for: kind)

        TimelineView(.animation(minimumInterval: 1.0 / Self.framesPerSecond, paused: isCallingAttention)) { timeline in
            let index: Int = {
                guard !frames.isEmpty else { return 0 }
                if isCallingAttention { return 0 } // settle on a neutral pose while centred
                let tick = Int(timeline.date.timeIntervalSinceReferenceDate * Self.framesPerSecond)
                return tick % frames.count
            }()

            Group {
                if frames.indices.contains(index) {
                    Image(decorative: frames[index], scale: 1, orientation: .up)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.clear
                }
            }
            .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
        }
        .frame(width: 132, height: 104)
        .offset(y: isCallingAttention ? -4 : 0)
        .animation(.spring(response: 0.34, dampingFraction: 0.55), value: isCallingAttention)
        .accessibilityLabel("Pixel pet")
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach(PetKind.allCases, id: \.self) { kind in
            VStack {
                PetIllustration(kind: kind)
                PetIllustration(kind: kind, facingLeft: true)
            }
        }
    }
    .padding()
    .background(Color(white: 0.15))
}
