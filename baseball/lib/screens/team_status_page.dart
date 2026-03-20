import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class TeamStatusPage extends StatefulWidget {
  final String? myTeam;
  final VoidCallback? onChangeTeam;

  const TeamStatusPage({Key? key, this.myTeam, this.onChangeTeam})
      : super(key: key);

  @override
  State<TeamStatusPage> createState() => _TeamStatusPageState();
}

class _TeamStatusPageState extends State<TeamStatusPage> {
  Map<String, dynamic>? data;
  String? error;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if (widget.myTeam != null) {
      fetchScore();
      timer =
          Timer.periodic(const Duration(minutes: 1), (_) => fetchScore());
    }
  }

  Future<void> fetchScore() async {
    if (widget.myTeam == null) return;
    try {
      final encoded = Uri.encodeComponent(widget.myTeam!);
      final url = '$kBaseUrl/score?team=$encoded';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;
        setState(() {
          data = decoded;
          error = null;
        });
      } else {
        throw Exception('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _resultText(String status) {
    if (status.contains('승')) return 'WIN';
    if (status.contains('패')) return 'LOSE';
    if (status.contains('무')) return 'DRAW';
    if (status.contains('진행') || status.contains('경기중')) return 'LIVE';
    return status;
  }

  Color _resultColor(String status) {
    if (status.contains('승')) return const Color(0xFF1565C0);
    if (status.contains('패')) return Colors.red;
    if (status.contains('무')) return Colors.grey;
    if (status.contains('진행') || status.contains('경기중'))
      return const Color(0xFF009933);
    return Colors.grey;
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

  // "승김진욱" → {'badge': '승', 'name': '김진욱'}
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _backgroundImage() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: 0.45,
        child: Image.asset(
          'assets/logos/bgimg.png',
          fit: BoxFit.fitWidth,
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
                '마이팀',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),

          Expanded(
            child: widget.myTeam == null
                ? _buildEmptyState()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        _backgroundImage(),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_baseball_outlined,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                '응원할 구단을 선택해주세요',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: widget.onChangeTeam,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('마이팀 설정하기',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (error != null) {
      return Stack(
        children: [
          _backgroundImage(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('오류가 발생했습니다.',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: fetchScore, child: const Text('다시 시도')),
              ],
            ),
          ),
        ],
      );
    }

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data!.containsKey('error')) {
      return Stack(
        children: [
          _backgroundImage(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data!['error'],
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: fetchScore, child: const Text('다시 시도')),
              ],
            ),
          ),
        ],
      );
    }

    final myTeamName = data!['my_team'] ?? widget.myTeam ?? '';
    final myLogo = data!['my_logo'] ?? '';
    final opponentLogo = data!['opponent_logo'] ?? '';
    final opponent = data!['opponent'] ?? '';
    final myPitcherRaw = data!['my_pitcher'] ?? '';
    final opponentPitcherRaw = data!['opponent_pitcher'] ?? '';
    final status = data!['status'] ?? '';
    final myScore = data!['my_score']?.toString() ?? '';
    final opponentScore = data!['opponent_score']?.toString() ?? '';
    final isScheduled = status == '경기예정';
    final hasScore = myScore.isNotEmpty && opponentScore.isNotEmpty;

    final myPitcher = _parsePitcher(myPitcherRaw);
    final opponentPitcher = _parsePitcher(opponentPitcherRaw);

    return Stack(
      children: [
        _backgroundImage(),
        RefreshIndicator(
          onRefresh: fetchScore,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 팀 헤더 (내 팀 + 마이팀 변경 버튼)
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _logo(myLogo, 32),
                      const SizedBox(width: 10),
                      Text(
                        myTeamName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onChangeTeam,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('마이팀 변경',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),

                const SizedBox(height: 24),

                // WIN / LOSE / LIVE 텍스트
                if (!isScheduled && status.isNotEmpty) ...[
                  Text(
                    _resultText(status),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _resultColor(status),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 경기 카드
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 로고 + 스코어
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // 상대팀 (왼쪽)
                          Column(
                            children: [
                              _logo(opponentLogo, 56),
                              const SizedBox(height: 6),
                              Text(opponent,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666))),
                            ],
                          ),

                          // 스코어 / VS
                          Column(
                            children: [
                              if (hasScore)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      opponentScore,
                                      style: const TextStyle(
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(':',
                                          style: TextStyle(
                                              fontSize: 44,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFAAAAAA))),
                                    ),
                                    Text(
                                      myScore,
                                      style: const TextStyle(
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A)),
                                    ),
                                  ],
                                )
                              else
                                const Text('VS',
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                              const SizedBox(height: 6),
                              // 상태 배지
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusBgColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(status)),
                                ),
                              ),
                            ],
                          ),

                          // 내 팀 (오른쪽)
                          Column(
                            children: [
                              _logo(myLogo, 56),
                              const SizedBox(height: 6),
                              Text(myTeamName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666))),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 12),

                      // 선발 투수 (승/패 뱃지 포함)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 상대팀 투수
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(opponentPitcher['name']!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF555555))),
                              _pitcherBadge(opponentPitcher['badge']!),
                            ],
                          ),
                          const Text('vs',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          // 내 팀 투수
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _pitcherBadge(myPitcher['badge']!),
                              Text(myPitcher['name']!,
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF555555))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
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
