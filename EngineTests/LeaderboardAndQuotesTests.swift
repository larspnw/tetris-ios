import XCTest
@testable import TetrisEngine

private final class MemoryStore: LeaderboardPersistence {
    var stored: [LeaderboardEntry] = []
    func loadEntries() -> [LeaderboardEntry] { stored }
    func saveEntries(_ entries: [LeaderboardEntry]) { stored = entries }
}

final class LeaderboardTests: XCTestCase {

    private func entry(_ mode: GameMode, score: Int = 0, time: Double = 0, t: Double = 0) -> LeaderboardEntry {
        LeaderboardEntry(mode: mode, score: score, lines: 0, timeSeconds: time,
                         date: Date(timeIntervalSince1970: t))
    }

    func testUltraRanksByScoreDescending() {
        let lb = Leaderboard(store: MemoryStore())
        lb.record(entry(.ultra, score: 100, t: 1))
        lb.record(entry(.ultra, score: 300, t: 2))
        lb.record(entry(.ultra, score: 200, t: 3))
        XCTAssertEqual(lb.sorted(mode: .ultra).map { $0.score }, [300, 200, 100])
        XCTAssertEqual(lb.best(mode: .ultra)?.score, 300)
    }

    func testSprintRanksByTimeAscending() {
        let lb = Leaderboard(store: MemoryStore())
        lb.record(entry(.sprint, score: 1, time: 50, t: 1))
        lb.record(entry(.sprint, score: 1, time: 30, t: 2))
        lb.record(entry(.sprint, score: 1, time: 40, t: 3))
        XCTAssertEqual(lb.sorted(mode: .sprint).map { $0.timeSeconds }, [30, 40, 50])
        XCTAssertEqual(lb.best(mode: .sprint)?.timeSeconds, 30)
    }

    func testRankReturnedOnRecord() {
        let lb = Leaderboard(store: MemoryStore())
        lb.record(entry(.ultra, score: 500, t: 1))
        let rank = lb.record(entry(.ultra, score: 100, t: 2))
        XCTAssertEqual(rank, 2)
    }

    func testCapPerMode() {
        let lb = Leaderboard(store: MemoryStore())
        for i in 0..<30 { lb.record(entry(.ultra, score: i, t: Double(i))) }
        XCTAssertEqual(lb.sorted(mode: .ultra).count, Leaderboard.maxPerMode)
        XCTAssertEqual(lb.best(mode: .ultra)?.score, 29)
    }

    func testPersistenceRoundTrip() {
        let store = MemoryStore()
        let lb = Leaderboard(store: store)
        lb.record(entry(.zen, score: 42, t: 1))
        let reloaded = Leaderboard(store: store)
        XCTAssertEqual(reloaded.best(mode: .zen)?.score, 42)
    }

    func testClear() {
        let store = MemoryStore()
        let lb = Leaderboard(store: store)
        lb.record(entry(.zen, score: 1, t: 1))
        lb.clear()
        XCTAssertTrue(lb.sorted(mode: .zen).isEmpty)
        XCTAssertTrue(store.stored.isEmpty)
    }

    func testEntriesAreModeIsolated() {
        let lb = Leaderboard(store: MemoryStore())
        lb.record(entry(.ultra, score: 100, t: 1))
        lb.record(entry(.zen, score: 200, t: 2))
        XCTAssertEqual(lb.sorted(mode: .ultra).count, 1)
        XCTAssertEqual(lb.sorted(mode: .zen).count, 1)
        XCTAssertTrue(lb.sorted(mode: .sprint).isEmpty)
    }
}

final class QuotesTests: XCTestCase {

    func testQuoteBookIsPopulated() {
        XCTAssertGreaterThanOrEqual(QuoteBook.all.count, 30)
        for q in QuoteBook.all {
            XCTAssertFalse(q.text.isEmpty)
            XCTAssertFalse(q.author.isEmpty)
        }
    }

    func testCoversAllThreeSources() {
        let authors = Set(QuoteBook.all.map { $0.author })
        XCTAssertTrue(authors.contains("Naval Ravikant"))
        XCTAssertTrue(authors.contains("Brad Stulberg"))
        // At least one Stoic.
        let stoics: Set = ["Marcus Aurelius", "Seneca", "Epictetus"]
        XCTAssertFalse(authors.isDisjoint(with: stoics))
    }

    func testRandomReturnsAKnownQuoteDeterministically() {
        var rng = SeededGenerator(seed: 99)
        let q = QuoteBook.random(using: &rng)
        XCTAssertTrue(QuoteBook.all.contains(q))
    }

    func testRandomQuoteUnseeded() {
        XCTAssertTrue(QuoteBook.all.contains(QuoteBook.random()))
    }
}

final class GameModeTests: XCTestCase {
    func testAllModesHaveDistinctMetadata() {
        XCTAssertEqual(GameMode.allCases.count, 3)
        for mode in GameMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.subtitle.isEmpty)
        }
        XCTAssertTrue(GameMode.sprint.ranksByTime)
        XCTAssertFalse(GameMode.ultra.ranksByTime)
        XCTAssertFalse(GameMode.zen.ranksByTime)
        XCTAssertEqual(GameMode(rawValue: "ultra"), .ultra)
    }
}
