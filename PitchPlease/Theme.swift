// Custom Theme System voor PitchPlease
// Deze file bevat alle kleuren, fonts en styling constanten voor een consistent design
import SwiftUI

// MARK: - Color Palette
extension Color {
    
    // Primary Brand Colors - Muziek geïnspireerde gradient kleuren
    static let pitchPrimary = Color(red: 0.15, green: 0.15, blue: 0.9)        // Deep blue
    static let pitchSecondary = Color(red: 0.4, green: 0.2, blue: 0.8)        // Purple
    static let pitchAccent = Color(red: 1.0, green: 0.3, blue: 0.7)           // Pink/magenta
    
    // Background Colors
    static let pitchBackground = Color(red: 0.05, green: 0.05, blue: 0.1)     // Very dark blue
    static let pitchSurface = Color(red: 0.1, green: 0.1, blue: 0.15)         // Dark surface
    static let pitchCard = Color(red: 0.15, green: 0.15, blue: 0.2)           // Card background
    
    // Text Colors
    static let pitchText = Color.white
    static let pitchTextSecondary = Color(red: 0.8, green: 0.8, blue: 0.9)
    static let pitchTextTertiary = Color(red: 0.6, green: 0.6, blue: 0.7)
    
    // Functional Colors
    static let pitchSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let pitchWarning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let pitchError = Color(red: 1.0, green: 0.3, blue: 0.3)
    
    // Star Rating Colors
    static let pitchStarFilled = Color(red: 1.0, green: 0.8, blue: 0.0)       // Golden yellow
    static let pitchStarEmpty = Color(red: 0.3, green: 0.3, blue: 0.4)        // Dark gray
}

// MARK: - Gradients
extension LinearGradient {
    
    // Primary app gradient
    static let pitchPrimaryGradient = LinearGradient(
        colors: [Color.pitchPrimary, Color.pitchSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Accent gradient voor buttons en highlights
    static let pitchAccentGradient = LinearGradient(
        colors: [Color.pitchSecondary, Color.pitchAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Subtle card gradient
    static let pitchCardGradient = LinearGradient(
        colors: [Color.pitchCard, Color.pitchSurface],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Background gradient
    static let pitchBackgroundGradient = LinearGradient(
        colors: [Color.pitchBackground, Color.pitchSurface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct PitchTypography {
    
    // Font weights
    static let light: Font.Weight = .light
    static let regular: Font.Weight = .regular
    static let medium: Font.Weight = .medium
    static let semibold: Font.Weight = .semibold
    static let bold: Font.Weight = .bold
    
    // Font sizes
    static let title1 = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 15, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
}

// MARK: - Spacing
struct PitchSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius
struct PitchRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let circle: CGFloat = 50
}

// MARK: - Shadows
extension View {
    
    func pitchShadowSmall() -> some View {
        self.shadow(
            color: Color.black.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    func pitchShadowMedium() -> some View {
        self.shadow(
            color: Color.black.opacity(0.4),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    func pitchShadowLarge() -> some View {
        self.shadow(
            color: Color.black.opacity(0.5),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    func pitchGlow(color: Color = Color.pitchAccent) -> some View {
        self.shadow(
            color: color.opacity(0.6),
            radius: 10,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Animation Presets
extension Animation {
    static let pitchSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let pitchEaseOut = Animation.easeOut(duration: 0.3)
    static let pitchBouncy = Animation.interpolatingSpring(stiffness: 300, damping: 15)
}

// MARK: - Custom Button Styles
struct PitchPrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    let fullWidth: Bool
    
    init(isDisabled: Bool = false, fullWidth: Bool = true) {
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PitchTypography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 56)
            .padding(.horizontal, PitchSpacing.lg)
            .background(
                Group {
                    if isDisabled {
                        Color.gray.opacity(0.3)
                    } else {
                        LinearGradient.pitchAccentGradient
                    }
                }
            )
            .cornerRadius(PitchRadius.lg)
            .pitchShadowMedium()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.pitchSpring, value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

struct PitchSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PitchTypography.headline)
            .foregroundColor(.pitchPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: PitchRadius.lg)
                    .stroke(LinearGradient.pitchPrimaryGradient, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: PitchRadius.lg)
                            .fill(Color.pitchCard.opacity(0.5))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.pitchSpring, value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct PitchCardStyle: ViewModifier {
    let padding: CGFloat
    
    init(padding: CGFloat = PitchSpacing.md) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: PitchRadius.lg)
                    .fill(LinearGradient.pitchCardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PitchRadius.lg)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .pitchShadowMedium()
    }
}

extension View {
    func pitchCard(padding: CGFloat = PitchSpacing.md) -> some View {
        self.modifier(PitchCardStyle(padding: padding))
    }
}

// MARK: - Glassmorphism Effect
struct GlassmorphismBackground: ViewModifier {
    let opacity: Double
    
    init(opacity: Double = 0.1) {
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: PitchRadius.lg)
                    .fill(Color.white.opacity(opacity))
                    .background(.ultraThinMaterial)
            )
    }
}

extension View {
    func glassmorphism(opacity: Double = 0.1) -> some View {
        self.modifier(GlassmorphismBackground(opacity: opacity))
    }
} 