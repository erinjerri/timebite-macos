import SwiftUI

struct IkigaiIconView: View {
    var size: CGFloat = 28
    var lineWidth: CGFloat = 1.9
    var color: Color = .white

    var body: some View {
        ZStack {
            ForEach(circleFrames.indices, id: \.self) { index in
                Circle()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: circleFrames[index].width, height: circleFrames[index].height)
                    .offset(circleFrames[index].offset)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var circleFrames: [(width: CGFloat, height: CGFloat, offset: CGSize)] {
        let circleSize = size * 0.56
        let horizontalOffset = size * 0.18
        let verticalOffset = size * 0.18

        return [
            (circleSize, circleSize, CGSize(width: 0, height: -verticalOffset)),
            (circleSize, circleSize, CGSize(width: -horizontalOffset, height: 0)),
            (circleSize, circleSize, CGSize(width: horizontalOffset, height: 0)),
            (circleSize, circleSize, CGSize(width: 0, height: verticalOffset)),
        ]
    }
}

#Preview {
    ZStack {
        Color.black
        IkigaiIconView(size: 40, lineWidth: 2.1)
    }
    .frame(width: 120, height: 120)
}
