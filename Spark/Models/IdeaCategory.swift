import Foundation

enum IdeaCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case dining = "Dining"
    case outdoors = "Outdoors"
    case entertainment = "Entertainment"
    case adventure = "Adventure"
    case stayIn = "Stay-in"
    case travel = "Travel"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .dining: "fork.knife"
        case .outdoors: "leaf"
        case .entertainment: "film"
        case .adventure: "figure.hiking"
        case .stayIn: "house"
        case .travel: "airplane"
        }
    }

    var emoji: String {
        switch self {
        case .dining: "🍽️"
        case .outdoors: "🌳"
        case .entertainment: "🎬"
        case .adventure: "🧗"
        case .stayIn: "🛋️"
        case .travel: "✈️"
        }
    }
}
