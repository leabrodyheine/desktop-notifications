import Foundation
import SwiftUI

/// The placeholder pets that reminders rotate through. Each is drawn with
/// vector primitives so artwork can be swapped later without touching calendar
/// or presentation logic.
enum PetKind: String, CaseIterable, Sendable {
    case calicoCat
    case greyTabbyCat
    case orangeCat
    case hamster
}

struct PetPalette {
    var fur: Color
    var patch: Color
    var belly: Color
    var secondaryPatch: Color

    static let ink = Color(red: 0.17, green: 0.15, blue: 0.16)
    static let blush = Color(red: 0.97, green: 0.66, blue: 0.71)
    static let earPink = Color(red: 1.0, green: 0.83, blue: 0.86)

    static let calico = PetPalette(
        fur: Color(red: 0.99, green: 0.96, blue: 0.92),
        patch: Color(red: 0.94, green: 0.66, blue: 0.40),
        belly: Color(red: 1.0, green: 0.99, blue: 0.97),
        secondaryPatch: Color(red: 0.55, green: 0.57, blue: 0.61)
    )
    static let orange = PetPalette(
        fur: Color(red: 0.97, green: 0.73, blue: 0.44),
        patch: Color(red: 0.89, green: 0.57, blue: 0.29),
        belly: Color(red: 1.0, green: 0.93, blue: 0.83),
        secondaryPatch: Color(red: 0.89, green: 0.57, blue: 0.29)
    )
    static let greyTabby = PetPalette(
        fur: Color(red: 0.83, green: 0.84, blue: 0.86),
        patch: Color(red: 0.58, green: 0.60, blue: 0.64),
        belly: Color(red: 0.96, green: 0.96, blue: 0.97),
        secondaryPatch: Color(red: 0.58, green: 0.60, blue: 0.64)
    )
    static let hamster = PetPalette(
        fur: Color(red: 0.96, green: 0.85, blue: 0.66),
        patch: Color(red: 0.85, green: 0.71, blue: 0.49),
        belly: Color(red: 1.0, green: 0.98, blue: 0.94),
        secondaryPatch: Color(red: 0.85, green: 0.71, blue: 0.49)
    )
}

struct PetIllustration: View {
    var kind: PetKind
    var isCallingAttention: Bool = false

    private static let designSize = CGSize(width: 120, height: 128)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isCallingAttention)) { timeline in
            Canvas { context, size in
                context.transform = CGAffineTransform(
                    scaleX: size.width / Self.designSize.width,
                    y: size.height / Self.designSize.height
                )
                let time = timeline.date.timeIntervalSinceReferenceDate

                switch kind {
                case .calicoCat:
                    drawSittingCat(context, palette: .calico, multicolor: true, wave: nil)
                case .greyTabbyCat:
                    drawLoafCat(context, palette: .greyTabby)
                case .orangeCat:
                    let wiggle = isCallingAttention ? CGFloat(sin(time * 8)) * 0.35 : 0
                    drawSittingCat(context, palette: .orange, multicolor: false, wave: 0.15 + wiggle)
                case .hamster:
                    drawHamster(context)
                }
            }
        }
        .frame(width: Self.designSize.width, height: Self.designSize.height)
        .scaleEffect(isCallingAttention ? 1.06 : 1.0, anchor: .bottom)
        .offset(y: isCallingAttention ? -4 : 0)
        .animation(.easeInOut(duration: 0.34).repeatForever(autoreverses: true), value: isCallingAttention)
        .overlay(alignment: .top) {
            if isCallingAttention {
                Text("!")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color(red: 1.0, green: 0.79, blue: 0.24)))
                    .overlay(Circle().stroke(PetPalette.ink, lineWidth: 2))
                    .offset(x: 30, y: -2)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.6), value: isCallingAttention)
    }
}

// MARK: - Geometry helpers

private func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
}

private func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ radius: CGFloat) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius)
}

private func triangleUp(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: x + w / 2, y: y))
    path.addLine(to: CGPoint(x: x + w, y: y + h))
    path.addLine(to: CGPoint(x: x, y: y + h))
    path.closeSubpath()
    return path
}

private func triangleDown(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: x, y: y))
    path.addLine(to: CGPoint(x: x + w, y: y))
    path.addLine(to: CGPoint(x: x + w / 2, y: y + h))
    path.closeSubpath()
    return path
}

private func segment(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: x1, y: y1))
    path.addLine(to: CGPoint(x: x2, y: y2))
    return path
}

/// A shallow downward-bulging curve, used for closed "happy" eyes.
private func smileArc(_ centerX: CGFloat, _ centerY: CGFloat, _ width: CGFloat, _ depth: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: centerX - width / 2, y: centerY))
    path.addQuadCurve(
        to: CGPoint(x: centerX + width / 2, y: centerY),
        control: CGPoint(x: centerX, y: centerY + depth)
    )
    return path
}

private func mouthShape(_ centerX: CGFloat, _ centerY: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: centerX - 5, y: centerY))
    path.addQuadCurve(to: CGPoint(x: centerX, y: centerY + 3.5), control: CGPoint(x: centerX - 2.5, y: centerY + 3.5))
    path.addQuadCurve(to: CGPoint(x: centerX + 5, y: centerY), control: CGPoint(x: centerX + 2.5, y: centerY + 3.5))
    return path
}

private func rotate(_ path: Path, _ radians: CGFloat, around center: CGPoint) -> Path {
    path.applying(
        CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: radians)
            .translatedBy(x: -center.x, y: -center.y)
    )
}

// MARK: - Drawing helpers

private func fillOutlined(_ context: GraphicsContext, _ path: Path, _ fill: Color, lineWidth: CGFloat = 3) {
    context.fill(path, with: .color(fill))
    context.stroke(path, with: .color(PetPalette.ink), lineWidth: lineWidth)
}

private func stroke(_ context: GraphicsContext, _ path: Path, _ color: Color = PetPalette.ink, lineWidth: CGFloat = 2) {
    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
}

private func eyes(_ context: GraphicsContext, leftX: CGFloat, rightX: CGFloat, y: CGFloat, width: CGFloat = 8, height: CGFloat = 11) {
    context.fill(oval(leftX, y, width, height), with: .color(PetPalette.ink))
    context.fill(oval(rightX, y, width, height), with: .color(PetPalette.ink))
    context.fill(oval(leftX + width * 0.2, y + 1.5, 3, 3), with: .color(.white))
    context.fill(oval(rightX + width * 0.2, y + 1.5, 3, 3), with: .color(.white))
}

private func blush(_ context: GraphicsContext, leftX: CGFloat, rightX: CGFloat, y: CGFloat, width: CGFloat = 13, height: CGFloat = 8) {
    context.fill(oval(leftX, y, width, height), with: .color(PetPalette.blush.opacity(0.5)))
    context.fill(oval(rightX, y, width, height), with: .color(PetPalette.blush.opacity(0.5)))
}

// MARK: - Pets

private func drawSittingCat(_ context: GraphicsContext, palette: PetPalette, multicolor: Bool, wave: CGFloat?) {
    // Tail behind the body.
    let tail = rotate(roundedRect(74, 52, 20, 58, 10), 0.5, around: CGPoint(x: 84, y: 84))
    fillOutlined(context, tail, palette.fur)

    // Body with clipped belly / colour patches.
    let body = oval(16, 50, 88, 78)
    context.fill(body, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: body)
        layer.fill(oval(38, 78, 44, 52), with: .color(palette.belly))
        if multicolor {
            layer.fill(oval(8, 44, 46, 44), with: .color(palette.patch))
            layer.fill(oval(66, 56, 52, 46), with: .color(palette.secondaryPatch))
        }
    }
    context.stroke(body, with: .color(PetPalette.ink), lineWidth: 3)

    // Front paws (right paw is replaced by a raised arm when waving).
    fillOutlined(context, oval(34, 106, 24, 17), palette.fur)
    stroke(context, segment(42, 109, 42, 118), PetPalette.ink, lineWidth: 1.5)
    stroke(context, segment(50, 109, 50, 118), PetPalette.ink, lineWidth: 1.5)
    if wave == nil {
        fillOutlined(context, oval(62, 106, 24, 17), palette.fur)
        stroke(context, segment(70, 109, 70, 118), PetPalette.ink, lineWidth: 1.5)
        stroke(context, segment(78, 109, 78, 118), PetPalette.ink, lineWidth: 1.5)
    }

    // Ears drawn before the head so the head covers their base.
    fillOutlined(context, triangleUp(26, -4, 28, 24), palette.fur)
    fillOutlined(context, triangleUp(66, -4, 28, 24), multicolor ? palette.patch : palette.fur)

    // Head.
    let head = oval(27, 10, 66, 62)
    context.fill(head, with: .color(palette.fur))
    if multicolor {
        context.drawLayer { layer in
            layer.clip(to: head)
            layer.fill(oval(56, 4, 42, 42), with: .color(palette.patch))
        }
    }
    context.stroke(head, with: .color(PetPalette.ink), lineWidth: 3)

    // Inner ears near the tips.
    context.fill(triangleUp(33, 3, 12, 12), with: .color(PetPalette.earPink))
    context.fill(triangleUp(75, 3, 12, 12), with: .color(PetPalette.earPink))

    // Face.
    eyes(context, leftX: 45, rightX: 67, y: 36)
    context.fill(triangleDown(57, 48, 6, 5), with: .color(PetPalette.blush))
    stroke(context, mouthShape(60, 52))
    blush(context, leftX: 33, rightX: 74, y: 46)

    // Whiskers.
    stroke(context, segment(18, 44, 34, 47), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
    stroke(context, segment(18, 52, 34, 52), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
    stroke(context, segment(102, 44, 86, 47), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
    stroke(context, segment(102, 52, 86, 52), PetPalette.ink.opacity(0.45), lineWidth: 1.5)

    // Raised, waving paw.
    if let wave {
        let shoulder = CGPoint(x: 80, y: 96)
        fillOutlined(context, rotate(roundedRect(73, 54, 15, 44, 7.5), wave, around: shoulder), palette.fur)
        fillOutlined(context, rotate(oval(69, 44, 21, 19), wave, around: shoulder), palette.fur)
    }
}

private func drawLoafCat(_ context: GraphicsContext, palette: PetPalette) {
    // Tail curled around the front.
    let tail = rotate(roundedRect(82, 96, 40, 16, 8), -0.15, around: CGPoint(x: 102, y: 104))
    fillOutlined(context, tail, palette.fur)

    // A loaf is a single rounded blob: head and body share one outline.
    let body = roundedRect(13, 44, 98, 72, 33)
    context.fill(body, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: body)
        for index in 0..<7 {
            let stripeX = 34 + CGFloat(index) * 11
            layer.fill(roundedRect(stripeX, 40, 7, 34, 3.5), with: .color(palette.patch))
        }
        layer.fill(roundedRect(47, 44, 6, 18, 3), with: .color(palette.patch))
        layer.fill(roundedRect(57, 42, 6, 20, 3), with: .color(palette.patch))
        layer.fill(roundedRect(67, 44, 6, 18, 3), with: .color(palette.patch))
    }
    context.stroke(body, with: .color(PetPalette.ink), lineWidth: 3)

    // Ears sit on the top curve.
    fillOutlined(context, triangleUp(30, 24, 25, 24), palette.fur)
    fillOutlined(context, triangleUp(59, 24, 25, 24), palette.fur)
    context.fill(triangleUp(37, 31, 11, 11), with: .color(PetPalette.earPink))
    context.fill(triangleUp(66, 31, 11, 11), with: .color(PetPalette.earPink))

    // Sleepy face on the upper half of the loaf.
    stroke(context, smileArc(48, 62, 12, 5), PetPalette.ink, lineWidth: 2.5)
    stroke(context, smileArc(68, 62, 12, 5), PetPalette.ink, lineWidth: 2.5)
    context.fill(triangleDown(55, 67, 6, 4), with: .color(PetPalette.blush))
    stroke(context, mouthShape(58, 71))
    blush(context, leftX: 36, rightX: 67, y: 65, width: 13, height: 8)

    // Paws tucked under the loaf.
    stroke(context, smileArc(48, 114, 13, 4), PetPalette.ink.opacity(0.6), lineWidth: 2)
    stroke(context, smileArc(68, 114, 13, 4), PetPalette.ink.opacity(0.6), lineWidth: 2)
}

private func drawHamster(_ context: GraphicsContext) {
    let palette = PetPalette.hamster

    // Feet.
    fillOutlined(context, oval(32, 110, 18, 12), palette.fur)
    fillOutlined(context, oval(70, 110, 18, 12), palette.fur)

    // Ears behind the body.
    fillOutlined(context, oval(22, 20, 22, 22), palette.fur)
    fillOutlined(context, oval(76, 20, 22, 22), palette.fur)
    context.fill(oval(28, 26, 11, 11), with: .color(PetPalette.earPink))
    context.fill(oval(82, 26, 11, 11), with: .color(PetPalette.earPink))

    // Round body with a clipped belly.
    let body = oval(12, 22, 96, 98)
    context.fill(body, with: .color(palette.fur))
    context.drawLayer { layer in
        layer.clip(to: body)
        layer.fill(oval(32, 52, 56, 66), with: .color(palette.belly))
    }
    context.stroke(body, with: .color(PetPalette.ink), lineWidth: 3)

    // Little arms held together.
    fillOutlined(context, oval(40, 84, 17, 16), palette.fur)
    fillOutlined(context, oval(63, 84, 17, 16), palette.fur)

    // Face.
    eyes(context, leftX: 43, rightX: 68, y: 52, width: 9, height: 12)
    context.fill(triangleDown(56, 66, 8, 6), with: .color(PetPalette.blush))
    stroke(context, mouthShape(60, 71))
    blush(context, leftX: 25, rightX: 76, y: 64, width: 18, height: 12)

    // Whiskers.
    stroke(context, segment(18, 60, 40, 63), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
    stroke(context, segment(18, 69, 40, 68), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
    stroke(context, segment(102, 60, 80, 63), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
    stroke(context, segment(102, 69, 80, 68), PetPalette.ink.opacity(0.45), lineWidth: 1.5)
}

#Preview {
    HStack(spacing: 16) {
        ForEach(PetKind.allCases, id: \.self) { kind in
            VStack {
                PetIllustration(kind: kind)
                PetIllustration(kind: kind, isCallingAttention: true)
            }
        }
    }
    .padding()
}
