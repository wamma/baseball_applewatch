import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/game_info.dart';
import '../config.dart';

class AllGamesPage extends StatefulWidget {
  @override
  _AllGamesPageState createState() => _AllGamesPageState();
}

class _AllGamesPageState extends State<AllGamesPage> {
  List<GameInfo> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllGames();
  }

  Future<void> fetchAllGames() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$kBaseUrl/games"));
      if (response.statusCode != 200) throw Exception("서버 응답 오류");

      final data = json.decode(utf8.decode(response.bodyBytes));
      final list =
          (data['games'] as List).map((e) => GameInfo.fromJson(e)).toList();
      setState(() {
        games = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _statusColor(String status) {
    if (status.contains('진행') || status.contains('경기중'))
      return const Color(0xFF009933);
    if (status.contains('종료')) return const Color(0xFF888888);
    if (status.contains('예정')) return const Color(0xFFFF9900);
    return const Color(0xFF888888);
  }

  Color _statusBgColor(String status) {
    if (status.contains('진행') || status.contains('경기중'))
      return const Color(0xFFDEF2E0);
    if (status.contains('종료')) return const Color(0xFFF0F0F0);
    if (status.contains('예정')) return const Color(0xFFFFF3E0);
    return const Color(0xFFF0F0F0);
  }

  // "승김영우" → {'badge': '승', 'name': '김영우'}
  Map<String, String> _parsePitcher(String pitcher) {
    if (pitcher.startsWith('승')) {
      return {'badge': '승', 'name': pitcher.substring(1)};
    }
    if (pitcher.startsWith('패')) {
      return {'badge': '패', 'name': pitcher.substring(1)};
    }
    return {'badge': '', 'name': pitcher};
  }

  Widget _pitcherBadge(String badge) {
    if (badge.isEmpty) return const SizedBox.shrink();
    final isWin = badge == '승';
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isWin ? const Color(0xFF1565C0) : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badge,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 헤더
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: const Center(
              child: Text(
                '전체 경기 보기',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),

          // 경기 목록
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    color: const Color(0xFFF5F5F5),
                    child: RefreshIndicator(
                      onRefresh: fetchAllGames,
                      child: games.isEmpty
                          ? const Center(
                              child: Text('경기 정보가 없습니다.',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: games.length,
                              itemBuilder: (context, index) {
                                return _buildGameCard(games[index]);
                              },
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameInfo game) {
    final hasScore = game.awayScore != null && game.homeScore != null;
    final awayPitcher = _parsePitcher(game.awayPitcher);
    final homePitcher = _parsePitcher(game.homePitcher);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // 스코어 행
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 어웨이팀
                Row(
                  children: [
                    _logo(game.awayLogo, 44),
                    const SizedBox(width: 8),
                    if (hasScore)
                      Text(
                        game.awayScore!,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                      ),
                  ],
                ),

                // 상태 배지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBgColor(game.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(game.status),
                    ),
                  ),
                ),

                // 홈팀
                Row(
                  children: [
                    if (hasScore)
                      Text(
                        game.homeScore!,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                      ),
                    const SizedBox(width: 8),
                    _logo(game.homeLogo, 44),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 선발 투수 행 (승/패 뱃지 포함)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 어웨이 투수
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(awayPitcher['name']!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                    _pitcherBadge(awayPitcher['badge']!),
                  ],
                ),
                const Text('vs',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                // 홈 투수
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _pitcherBadge(homePitcher['badge']!),
                    Text(homePitcher['name']!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo(String url, double size) {
    if (url.isEmpty) {
      return Icon(Icons.sports_baseball,
          size: size, color: Colors.grey[300]);
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.sports_baseball, size: size, color: Colors.grey[300]),
    );
  }
}
