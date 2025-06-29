import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/game_info.dart';

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
    try {
      final response = await http.get(Uri.parse("https://petition-lies-definitely-fitness.trycloudflare.com/games"));
      if (response.statusCode != 200) throw Exception("서버 응답 오류");

      final data = json.decode(utf8.decode(response.bodyBytes));
      final list = (data['games'] as List).map((e) => GameInfo.fromJson(e)).toList();
      setState(() {
        games = list;
        isLoading = false;
      });
    } catch (e) {
      print("AllGamesPage fetch 에러: $e");
      setState(() {
        isLoading = false;
      });
      // 에러 다이얼로그 등 보여줄 수도 있음
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("전체 경기 보기")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAllGames,
              child: ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      leading: Image.network(game.awayLogo, width: 40, errorBuilder: (_, __, ___) => Icon(Icons.sports_baseball)),
                      title: Text("${game.awayTeam} vs ${game.homeTeam}"),
                      subtitle: Text("선발: ${game.awayPitcher} vs ${game.homePitcher}\n상태: ${game.status}"),
                      trailing: Image.network(game.homeLogo, width: 40, errorBuilder: (_, __, ___) => Icon(Icons.sports_baseball)),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
