import Foundation

/// An inspirational quote shown on launch and between games.
public struct Quote: Equatable, Sendable {
    public let text: String
    public let author: String
    public init(text: String, author: String) {
        self.text = text
        self.author = author
    }
}

/// Curated quotes: Stoic philosophers, Brad Stulberg, and Naval Ravikant.
public enum QuoteBook {
    public static func random(using rng: inout some RandomNumberGenerator) -> Quote {
        all.randomElement(using: &rng) ?? all[0]
    }

    public static func random() -> Quote {
        var g = SystemRandomNumberGenerator()
        return random(using: &g)
    }

    public static let all: [Quote] = [
        // Stoic
        Quote(text: "You have power over your mind — not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius"),
        Quote(text: "The impediment to action advances action. What stands in the way becomes the way.", author: "Marcus Aurelius"),
        Quote(text: "Waste no more time arguing about what a good person should be. Be one.", author: "Marcus Aurelius"),
        Quote(text: "If it is not right, do not do it; if it is not true, do not say it.", author: "Marcus Aurelius"),
        Quote(text: "We suffer more often in imagination than in reality.", author: "Seneca"),
        Quote(text: "Luck is what happens when preparation meets opportunity.", author: "Seneca"),
        Quote(text: "It is not that we have a short time to live, but that we waste a lot of it.", author: "Seneca"),
        Quote(text: "Difficulties strengthen the mind, as labor does the body.", author: "Seneca"),
        Quote(text: "He who fears death will never do anything worthy of a living person.", author: "Seneca"),
        Quote(text: "No man is free who is not master of himself.", author: "Epictetus"),
        Quote(text: "It's not what happens to you, but how you react to it that matters.", author: "Epictetus"),
        Quote(text: "First say to yourself what you would be; and then do what you have to do.", author: "Epictetus"),
        Quote(text: "Make the best use of what is in your power, and take the rest as it happens.", author: "Epictetus"),
        Quote(text: "Wealth consists not in having great possessions, but in having few wants.", author: "Epictetus"),

        // Brad Stulberg
        Quote(text: "Stress + rest = growth.", author: "Brad Stulberg"),
        Quote(text: "Be where you are so you can get to where you want to go.", author: "Brad Stulberg"),
        Quote(text: "Focus on the process, and let the outcome take care of itself.", author: "Brad Stulberg"),
        Quote(text: "Mastery requires patience. And patience requires presence.", author: "Brad Stulberg"),
        Quote(text: "Trade in your expectations for equanimity.", author: "Brad Stulberg"),
        Quote(text: "Confidence comes from doing the work, not from telling yourself you're great.", author: "Brad Stulberg"),
        Quote(text: "Sustainable excellence comes from playing the long game.", author: "Brad Stulberg"),
        Quote(text: "The goal isn't to feel good. The goal is to get good at feeling.", author: "Brad Stulberg"),

        // Naval Ravikant
        Quote(text: "Play long-term games with long-term people.", author: "Naval Ravikant"),
        Quote(text: "Learn to sell. Learn to build. If you can do both, you will be unstoppable.", author: "Naval Ravikant"),
        Quote(text: "Desire is a contract you make with yourself to be unhappy until you get what you want.", author: "Naval Ravikant"),
        Quote(text: "The most important skill for getting rich is becoming a perpetual learner.", author: "Naval Ravikant"),
        Quote(text: "A calm mind, a fit body, and a house full of love. These things cannot be bought.", author: "Naval Ravikant"),
        Quote(text: "Earn with your mind, not your time.", author: "Naval Ravikant"),
        Quote(text: "Read what you love until you love to read.", author: "Naval Ravikant"),
        Quote(text: "You're never going to get rich renting out your time.", author: "Naval Ravikant"),
        Quote(text: "Specific knowledge is found by pursuing your genuine curiosity.", author: "Naval Ravikant"),
        Quote(text: "Happiness is a choice you make and a skill you develop.", author: "Naval Ravikant"),
        Quote(text: "The greatest superpower is the ability to change yourself.", author: "Naval Ravikant"),
    ]
}
