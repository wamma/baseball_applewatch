import WidgetKit
import SwiftUI

private let kAppGroupID = "group.baseball.myteam"
private let kServerURL = "https://hearing-lang-continually-paris.trycloudflare.com"

// MARK: - Data Model

struct GameData {
    let myTeam: String
    let opponent: String
    let myScore: String
    let opponentScore: String
    let status: String

    var isLive: Bool {
        status.contains("회초") || status.contains("회말") || status.contains("진행") || status.contains("경기중")
    }

    var inningText: String {
        (status.contains("회초") || status.contains("회말")) ? status : ""
    }

    var resultText: String {
        if status.contains("승") { return "WIN" }
        if status.contains("패") { return "LOSE" }
        if status.contains("무") { return "DRAW" }
        if isLive { return "LIVE" }
        return "VS"
    }

    var resultColor: Color {
        if status.contains("승") { return Color(red: 0.08, green: 0.40, blue: 0.75) }
        if status.contains("패") { return .red }
        if isLive { return Color(red: 0, green: 0.6, blue: 0.2) }
        return .primary
    }
}

struct GameEntry: TimelineEntry {
    let date: Date
    let myTeam: String?
    let gameData: GameData?
}

// MARK: - Provider

struct GameProvider: TimelineProvider {
    func placeholder(in context: Context) -> GameEntry {
        GameEntry(
            date: Date(),
            myTeam: "두산 베어스",
            gameData: GameData(
                myTeam: "두산 베어스",
                opponent: "롯데",
                myScore: "3",
                opponentScore: "10",
                status: "패배"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GameEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GameEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: kAppGroupID)
        let myTeam = defaults?.string(forKey: "myTeam")

        guard let team = myTeam, !team.isEmpty else {
            let entry = GameEntry(date: Date(), myTeam: nil, gameData: nil)
            completion(Timeline(entries: [entry], policy: .atEnd))
            return
        }

        fetchGame(for: team) { gameData in
            let entry = GameEntry(date: Date(), myTeam: team, gameData: gameData)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchGame(for team: String, completion: @escaping (GameData?) -> Void) {
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
            completion(GameData(
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

struct MyTeamWidgetEntryView: View {
    let entry: GameEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.myTeam == nil {
                noTeamView
            } else if let game = entry.gameData {
                switch family {
                case .systemMedium:
                    mediumView(game)
                case .accessoryCircular:
                    circularView(game)
                case .accessoryRectangular:
                    rectangularView(game)
                case .accessoryInline:
                    inlineView(game)
                default:
                    smallView(game)
                }
            } else {
                switch family {
                case .accessoryInline:
                    Text("경기 없음")
                case .accessoryCircular:
                    Image(systemName: "baseball")
                default:
                    noGameView
                }
            }
        }
    }

    var noTeamView: some View {
        VStack(spacing: 8) {
            Image(systemName: "baseball")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            Text("마이팀을\n설정해주세요")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
    }

    var noGameView: some View {
        VStack(spacing: 6) {
            Text(entry.myTeam ?? "")
                .font(.caption).bold()
            Text("오늘 경기 없음")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    func smallView(_ game: GameData) -> some View {
        VStack(spacing: 4) {
            Text(entry.myTeam ?? "")
                .font(.caption2).bold()
                .lineLimit(1)
            Text(game.resultText)
                .font(.title2).bold()
                .foregroundColor(game.resultColor)
            if !game.myScore.isEmpty {
                Text("\(game.opponentScore) - \(game.myScore)")
                    .font(.callout).bold()
            }
            if game.isLive && !game.inningText.isEmpty {
                Text(game.inningText)
                    .font(.caption2).bold()
                    .foregroundColor(game.resultColor)
            }
            Text("vs \(game.opponent)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
    }

    // accessoryCircular - 잠금화면 원형
    func circularView(_ game: GameData) -> some View {
        VStack(spacing: 1) {
            Text(game.resultText)
                .font(.system(size: 14, weight: .bold))
                .widgetAccentable()
            if !game.myScore.isEmpty {
                Text("\(game.opponentScore):\(game.myScore)")
                    .font(.system(size: 11, weight: .semibold))
            }
        }
    }

    // accessoryRectangular - 잠금화면 직사각형
    func rectangularView(_ game: GameData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.myTeam ?? "")
                .font(.caption2).bold()
                .widgetAccentable()
            HStack(spacing: 4) {
                Text(game.resultText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(game.resultColor)
                if !game.myScore.isEmpty {
                    Text("\(game.opponentScore) : \(game.myScore)")
                        .font(.system(size: 14, weight: .semibold))
                }
                if game.isLive && !game.inningText.isEmpty {
                    Text(game.inningText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(game.resultColor)
                }
            }
            Text("vs \(game.opponent)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // accessoryInline - 잠금화면 한 줄
    @ViewBuilder
    func inlineView(_ game: GameData) -> some View {
        if game.myScore.isEmpty {
            Text("\(entry.myTeam ?? "") vs \(game.opponent)")
        } else if game.isLive && !game.inningText.isEmpty {
            Text("\(game.inningText) \(game.opponentScore):\(game.myScore) vs \(game.opponent)")
        } else {
            Text("\(game.resultText) \(game.opponentScore):\(game.myScore) vs \(game.opponent)")
        }
    }

    func mediumView(_ game: GameData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.myTeam ?? "")
                    .font(.subheadline).bold().lineLimit(1)
                Text(game.resultText)
                    .font(.largeTitle).bold()
                    .foregroundColor(game.resultColor)
                if game.isLive && !game.inningText.isEmpty {
                    Text(game.inningText)
                        .font(.caption).bold()
                        .foregroundColor(game.resultColor)
                }
            }
            Spacer()
            VStack(spacing: 4) {
                if !game.myScore.isEmpty {
                    HStack(spacing: 6) {
                        Text(game.opponentScore).font(.title).bold()
                        Text(":").font(.title).foregroundColor(.secondary)
                        Text(game.myScore).font(.title).bold()
                    }
                } else {
                    Text("VS").font(.title).bold().foregroundColor(.secondary)
                }
                Text("vs \(game.opponent)")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Widget

struct MyTeamWidget: Widget {
    let kind: String = "MyTeamWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GameProvider()) { entry in
            if #available(iOS 17.0, *) {
                MyTeamWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MyTeamWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("마이팀")
        .description("오늘 내 팀 경기 결과를 확인하세요.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

#Preview(as: .systemSmall) {
    MyTeamWidget()
} timeline: {
    GameEntry(
        date: .now,
        myTeam: "두산 베어스",
        gameData: GameData(myTeam: "두산 베어스", opponent: "롯데", myScore: "3", opponentScore: "10", status: "패배")
    )
}
