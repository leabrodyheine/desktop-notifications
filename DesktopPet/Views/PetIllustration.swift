import CoreGraphics
import ImageIO
import SwiftUI

/// The pets that reminders rotate through. Each ships as a horizontal
/// sprite sheet in the app bundle; the sheet is sliced once and the frames
/// are cycled to animate a walk.
enum PetKind: String, CaseIterable, Sendable {
    case bernese

    /// Resource name of the sprite sheet in the bundle.
    var assetName: String {
        switch self {
        case .bernese: return "bernese"
        }
    }

    /// Number of frames packed left-to-right in the sheet.
    var frameCount: Int {
        switch self {
        case .bernese: return 8
        }
    }

    /// Direction the artwork faces before any flip.
    var artFacesLeft: Bool {
        switch self {
        case .bernese: return true
        }
    }
}

/// Loads and caches the sliced frames for each pet's sprite sheet.
private enum SpriteCache {
    private static var cache: [PetKind: [CGImage]] = [:]

    static func frames(for kind: PetKind) -> [CGImage] {
        if let cached = cache[kind] { return cached }
        let sliced = load(kind.assetName, count: kind.frameCount)
        cache[kind] = sliced
        return sliced
    }

    private static func load(_ name: String, count: Int) -> [CGImage] {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png"),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return [] }

        let frameWidth = sheet.width / count
        let frameHeight = sheet.height
        return (0..<count).compactMap { index in
            sheet.cropping(to: CGRect(
                x: index * frameWidth, y: 0, width: frameWidth, height: frameHeight
            ))
        }
    }
}

struct PetIllustration: View {
    var kind: PetKind
    var isCallingAttention: Bool = false
    /// True when the pet is travelling right-to-left across the screen.
    var facingLeft: Bool = false

    private static let framesPerSecond = 10.0

    var body: some View {
        let frames = SpriteCache.frames(for: kind)
        // Flip so the pet faces its direction of travel.
        let flipped = facingLeft != kind.artFacesLeft

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
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.clear
                }
            }
            .scaleEffect(x: flipped ? -1 : 1, y: 1)
        }
        .frame(width: 104, height: 96)
        .offset(y: isCallingAttention ? -4 : 0)
        .animation(.spring(response: 0.34, dampingFraction: 0.55), value: isCallingAttention)
        .accessibilityLabel("Pet")
    }
}

#Preview {
    HStack(spacing: 8) {
        PetIllustration(kind: .bernese)
        PetIllustration(kind: .bernese, facingLeft: true)
    }
    .padding()
    .background(Color(white: 0.15))
}
