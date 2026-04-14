import SwiftUI

enum SparkTypography {
    static let displayHero: Font = .system(size: 34, weight: .semibold)
    static let displayHeroTracking: CGFloat = -0.28

    static let sectionHeading: Font = .system(size: 28, weight: .semibold)
    static let sectionHeadingTracking: CGFloat = -0.2

    static let cardTitle: Font = .system(size: 20, weight: .semibold)
    static let cardTitleTracking: CGFloat = 0.2
}

extension View {
    func sparkDisplayHero() -> some View {
        self.font(SparkTypography.displayHero)
            .tracking(SparkTypography.displayHeroTracking)
    }

    func sparkSectionHeading() -> some View {
        self.font(SparkTypography.sectionHeading)
            .tracking(SparkTypography.sectionHeadingTracking)
    }

    func sparkCardTitle() -> some View {
        self.font(SparkTypography.cardTitle)
            .tracking(SparkTypography.cardTitleTracking)
    }
}
