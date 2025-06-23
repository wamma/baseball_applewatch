class GameInfo {
  final String awayTeam;
  final String homeTeam;
  final String awayLogo;
  final String homeLogo;
  final String awayPitcher;
  final String homePitcher;
  final String status;

  GameInfo({
    required this.awayTeam,
    required this.homeTeam,
    required this.awayLogo,
    required this.homeLogo,
    required this.awayPitcher,
    required this.homePitcher,
    required this.status,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      awayTeam: json['away_team'],
      homeTeam: json['home_team'],
      awayLogo: json['away_logo'],
      homeLogo: json['home_logo'],
      awayPitcher: json['away_pitcher'],
      homePitcher: json['home_pitcher'],
      status: json['status'],
    );
  }
}
