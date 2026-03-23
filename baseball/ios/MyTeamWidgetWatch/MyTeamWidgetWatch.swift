import WidgetKit
import SwiftUI

private let kAppGroupID = "group.baseball.myteam"
private let kServerURL = "https://protocol-packet-floral-teacher.trycloudflare.com"

// MARK: - Data Model

struct WatchGameData {
    let myTeam: String
    let opponent: String
    let myScore: String
    let opponentScore: String
    let status: String

    var resultText: String {
        if status.contains("승") { return "WIN" }
        if status.contains("패") { return "LOSE" }
        if status.contains("무") { return "DRAW" }
        if status.contains("진행") || status.contains("경기중") { return "LIVE" }
        return "VS"
    }

    var resultColor: Color {
        if status.contains("승") { return Color(red: 0.08, green: 0.40, blue: 0.75) }
        if status.contains("패") { return .red }
        if status.contains("진행") || status.contains("경기중") { return Color(red: 0, green: 0.6, blue: 0.2) }
        return .primary
    }
}

struct WatchGameEntry: TimelineEntry {
    let date: Date
    let myTeam: String?
    let gameData: WatchGameData?
}

// MARK: - Provider

struct WatchGameProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchGameEntry {
        WatchGameEntry(
            date: Date(),
            myTeam: "두산 베어스",
            gameData: WatchGameData(
                myTeam: "두산 베어스",
                opponent: "롯데",
                myScore: "4",
                opponentScore: "1",
                status: "승리"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchGameEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchGameEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: kAppGroupID)
        let myTeam = defaults?.string(forKey: "myTeam")

        guard let team = myTeam, !team.isEmpty else {
            let entry = WatchGameEntry(date: Date(), myTeam: nil, gameData: nil)
            completion(Timeline(entries: [entry], policy: .atEnd))
            return
        }

        fetchGame(for: team) { gameData in
            let entry = WatchGameEntry(date: Date(), myTeam: team, gameData: gameData)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchGame(for team: String, completion: @escaping (WatchGameData?) -> Void) {
        guard let encoded = team.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(kServerURL)/score?team=\(encoded)") else {
            completion(nil); return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["error"] == nil else {
                completion(nil); return
            }
            let myScore       = (json["my_score"]      as? Int).map { "\($0)" } ?? ""
            let opponentScore = (json["opponent_score"] as? Int).map { "\($0)" } ?? ""
            completion(WatchGameData(
                myTeam: team,
                opponent: json["opponent"] as? String ?? "",
                myScore: myScore,
                opponentScore: opponentScore,
                status: json["status"] as? String ?? ""
            ))
        }.resume()
    }
}

// MARK: - Views

struct MyTeamWidgetWatchEntryView: View {
    let entry: WatchGameEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.myTeam == nil {
                noTeamView
            } else if let game = entry.gameData {
                switch family {
                case .accessoryRectangular:
                    rectangularView(game)
                case .accessoryCircular:
                    circularView(game)
                case .accessoryInline:
                    inlineView(game)
                default:
                    rectangularView(game)
                }
            } else {
                noGameView
            }
        }
    }

    var noTeamView: some View {
        VStack(spacing: 4) {
            Image(systemName: "baseball")
                .font(.system(size: 16))
            Text("팀 설정 필요")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    var noGameView: some View {
        VStack(spacing: 2) {
            Text(entry.myTeam ?? "")
                .font(.caption2).bold()
                .widgetAccentable()
            Text("오늘 경기 없음")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    func rectangularView(_ game: WatchGameData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.myTeam ?? "")
                .font(.caption2).bold()
                .widgetAccentable()
            HStack(spacing: 4) {
                Text(game.resultText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(game.resultColor)
                if !game.myScore.isEmpty {
                    Text("\(game.opponentScore):\(game.myScore)")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            Text("vs \(game.opponent)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    func circularView(_ game: WatchGameData) -> some View {
        VStack(spacing: 1) {
            Text(game.resultText)
                .font(.system(size: 13, weight: .bold))
                .widgetAccentable()
            if !game.myScore.isEmpty {
                Text("\(game.opponentScore):\(game.myScore)")
                    .font(.system(size: 10, weight: .semibold))
            }
        }
    }

    @ViewBuilder
    func inlineView(_ game: WatchGameData) -> some View {
        if game.myScore.isEmpty {
            Text("\(entry.myTeam ?? "") vs \(game.opponent)")
        } else {
            Text("\(game.resultText) \(game.opponentScore):\(game.myScore)")
        }
    }
}

// MARK: - Widget

struct MyTeamWidgetWatch: Widget {
    let kind: String = "MyTeamWidgetWatch"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchGameProvider()) { entry in
            if #available(watchOS 10.0, *) {
                MyTeamWidgetWatchEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MyTeamWidgetWatchEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("마이팀")
        .description("오늘 내 팀 경기 결과를 확인하세요.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
