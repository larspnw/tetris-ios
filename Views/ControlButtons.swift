import SwiftUI

/// A button that reports press-down and release separately, so it can drive DAS/ARR
/// auto-repeat for held movement. Targets are ≥44pt per Apple HIG.
struct HoldButton: View {
    let systemImage: String
    var onPress: () -> Void
    var onRelease: () -> Void = {}

    @State private var pressed = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(pressed ? 0.28 : 0.12)))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed { pressed = true; onPress() }
                    }
                    .onEnded { _ in
                        pressed = false; onRelease()
                    }
            )
    }
}

/// On-screen control pad for the Buttons scheme. Kept in the lower thumb zone.
struct ControlPad: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 10) {
                HoldButton(systemImage: "arrow.left",
                           onPress: { vm.moveLeftPressed() }, onRelease: { vm.horizontalReleased() })
                HoldButton(systemImage: "arrow.right",
                           onPress: { vm.moveRightPressed() }, onRelease: { vm.horizontalReleased() })
            }
            Spacer()
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    HoldButton(systemImage: "arrow.counterclockwise", onPress: { vm.rotate(clockwise: false) })
                    HoldButton(systemImage: "arrow.clockwise", onPress: { vm.rotate(clockwise: true) })
                }
                HStack(spacing: 10) {
                    HoldButton(systemImage: "tray.and.arrow.down", onPress: { vm.hold() })
                    HoldButton(systemImage: "arrow.down",
                               onPress: { vm.setSoftDrop(true) }, onRelease: { vm.setSoftDrop(false) })
                    HoldButton(systemImage: "arrow.down.to.line", onPress: { vm.hardDrop() })
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
