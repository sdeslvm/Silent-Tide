import SwiftUI

/// Loading overlay inspired by the retro hero screen while keeping the overall white shell.
struct SilentTideLoadingOverlay: View {
  let progress: Double
  private var progressPercentage: Int { Int(progress * 100) }

  var body: some View {
    ZStack(alignment: .bottom) {
      LinearGradient(colors: [Color.black, Color(red: 0.07, green: 0.07, blue: 0.1)], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()

      VStack(spacing: 24) {
        Spacer(minLength: 30)

        Text("SILENT TIDE")
          .font(.system(size: 34, weight: .black, design: .rounded))
          .kerning(4)
          .foregroundStyle(.white)
          .shadow(color: .white.opacity(0.08), radius: 10, y: 6)
          .overlay {
            LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .leading, endPoint: .trailing)
              .mask(
                Text("SILENT TIDE")
                  .font(.system(size: 34, weight: .black, design: .rounded))
                  .kerning(4)
              )
          }
          .accessibilityAddTraits(.isHeader)

        SilentTideHeroDisplay()

        SilentTideLoadingCard(progress: progress, progressPercentage: progressPercentage)

        Spacer(minLength: 20)
      }
      .padding(.horizontal, 32)

      SilentTideGroundStripe()
    }
  }
}

/// Pixelated hero pulled from the sprite sheet to mimic the in-game intro.
private struct SilentTideHeroDisplay: View {
  @State private var rotate = false
  @State private var pulse = false
  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(.white.opacity(0.08), lineWidth: 2)
        .frame(width: 190, height: 190)

      Circle()
        .stroke(AngularGradient(gradient: Gradient(colors: [.cyan.opacity(0.9), .purple.opacity(0.9), .cyan.opacity(0.9)]), center: .center), lineWidth: 4)
        .frame(width: 150, height: 150)
        .rotationEffect(.degrees(rotate ? 360 : 0))
        .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: rotate)

      // Orbital dots
      ZStack {
        ForEach(0..<6) { i in
          Circle()
            .fill(Color.white.opacity(0.9))
            .frame(width: 6, height: 6)
            .offset(x: 75)
            .rotationEffect(.degrees(Double(i) / 6.0 * 360))
            .rotationEffect(.degrees(rotate ? 360 : 0))
            .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: rotate)
        }
      }

      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .frame(width: 180, height: 56)
        .overlay {
          Text("Boot sequence")
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.9))
        }
        .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
        .scaleEffect(pulse ? 1.03 : 1.0)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
    }
    .frame(width: 200, height: 220)
    .onAppear {
      rotate = true
      pulse = true
    }
  }
}

/// White card that contains loading text and a slim progress bar.
private struct SilentTideLoadingCard: View {
  let progress: Double
  let progressPercentage: Int

  var body: some View {
    VStack(spacing: 14) {
      Text("Initializing systems…")
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)

      SilentTideProgressBar(progress: progress)
        .frame(height: 12)

      Text("\(progressPercentage)% • Syncing modules")
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .foregroundStyle(.white.opacity(0.7))
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 24)
    .background(.white.opacity(0.06))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .shadow(color: Color.black.opacity(0.6), radius: 18, y: 10)
  }
}

/// Simple black progress bar to fit the flat UI language.
private struct SilentTideProgressBar: View {
  let progress: Double

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      ZStack(alignment: .leading) {
        Capsule()
          .fill(LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.02)], startPoint: .top, endPoint: .bottom))

        // Filled portion
        Capsule()
          .fill(LinearGradient(colors: [.cyan, .blue, .purple], startPoint: .leading, endPoint: .trailing))
          .frame(width: max(12, min(CGFloat(progress) * width, width)))
          .shadow(color: .cyan.opacity(0.3), radius: 10, y: 0)
          .overlay(alignment: .trailing) {
            // Shimmer head
            Circle()
              .fill(.white.opacity(0.9))
              .frame(width: 10, height: 10)
              .offset(x: -3)
              .blur(radius: 0.5)
          }
      }
    }
  }
}

/// Tiled sand strip that anchors the composition and references the in-game floor texture.
private struct SilentTideGroundStripe: View {
  var body: some View {
    GeometryReader { geometry in
      let w = geometry.size.width
      ZStack {
        LinearGradient(colors: [.white.opacity(0.08), .clear], startPoint: .top, endPoint: .bottom)
        Rectangle()
          .fill(LinearGradient(colors: [.cyan.opacity(0.35), .blue.opacity(0.25), .purple.opacity(0.35)], startPoint: .leading, endPoint: .trailing))
          .frame(height: 2)
          .frame(maxWidth: .infinity, alignment: .leading)
          .overlay {
            // Moving scan line
            SilentTideScanline(width: w)
          }
          .offset(y: -6)
      }
    }
    .frame(height: 64)
  }
}

private struct SilentTideScanline: View {
  let width: CGFloat
  @State private var x: CGFloat = -200
  var body: some View {
    Rectangle()
      .fill(LinearGradient(colors: [.clear, .white.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing))
      .frame(width: 160, height: 2)
      .offset(x: x)
      .onAppear {
        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
          x = width + 160
        }
      }
  }
}

// MARK: - Previews

#if canImport(SwiftUI)
  import SwiftUI
#endif

// Use availability to keep using the modern #Preview API on iOS 17+ and provide a fallback for older versions
@available(iOS 17.0, *)
#Preview("Vertical") {
  SilentTideLoadingOverlay(progress: 0.2)
}

@available(iOS 17.0, *)
#Preview("Horizontal", traits: .landscapeRight) {
  SilentTideLoadingOverlay(progress: 0.2)
}

// Fallback previews for iOS < 17
struct SilentTideLoadingOverlay_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      SilentTideLoadingOverlay(progress: 0.2)
        .previewDisplayName("Vertical (Legacy)")

      SilentTideLoadingOverlay(progress: 0.2)
        .previewDisplayName("Horizontal (Legacy)")
        .previewLayout(.fixed(width: 812, height: 375))  // Simulate landscape on older previews
    }
  }
}
