import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

const Map<String, String> kboTeams = {
  'LG 트윈스': 'assets/logos/lg.png',
  'KT 위즈': 'assets/logos/kt.png',
  'SSG 랜더스': 'assets/logos/ssg.png',
  'NC 다이노스': 'assets/logos/nc.png',
  'KIA 타이거즈': 'assets/logos/kia.png',
  '두산 베어스': 'assets/logos/bears.png',
  '롯데 자이언츠': 'assets/logos/lotte.jpg',
  '삼성 라이온즈': 'assets/logos/samsung.png',
  '한화 이글스': 'assets/logos/hanhwa.jpg',
  '키움 히어로즈': 'assets/logos/kiwoom.png',
};

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My KBO Team',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TeamSelectionPage(),
    );
  }
}

class TeamSelectionPage extends StatefulWidget {
  @override
  _TeamSelectionPageState createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  String? selectedTeam;

  @override
  void initState() {
    super.initState();
    loadTeam();
  }

  Future<void> loadTeam() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTeam = prefs.getString('myTeam');
    });
  }

  Future<void> saveTeam(String team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myTeam', team);
    setState(() {
      selectedTeam = team;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('마이팀 설정')),
      body: ListView.builder(
        itemCount: kboTeams.length,
        itemBuilder: (context, index) {
          final team = kboTeams.keys.elementAt(index);
          final isSelected = team == selectedTeam;
          return ListTile(
            title: Text(team),
            leading: Image.asset(kboTeams[team]!),
            trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
            onTap: () => saveTeam(team),
          );
        },
      ),
      floatingActionButton: selectedTeam != null
          ? FloatingActionButton.extended(
              label: Text("다음"),
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TeamStatusPage(teamName: selectedTeam!),
                  ),
                );
              },
            )
          : null,
    );
  }
}

class TeamStatusPage extends StatefulWidget {
  final String teamName;

  const TeamStatusPage({required this.teamName});

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
    fetchScore();
    timer = Timer.periodic(Duration(minutes: 1), (_) => fetchScore());
  }

  Future<void> fetchScore() async {
    try {
      final encoded = Uri.encodeComponent(widget.teamName.replaceAll(" ", ""));
      final url = 'https://gc-suppliers-reservations-diego.trycloudflare.com/score?team=$encoded';
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
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(body: Center(child: Text("오류: $error")));
    }
    if (data == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (data!.containsKey('error')) {
      return Scaffold(body: Center(child: Text(data!['error'])));
    }

    final isScheduled = data!['status'] == '경기예정';

    return Scaffold(
      appBar: AppBar(title: Text('${data!['my_team']} 경기 정보')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 팀 로고, VS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Image.network(data!['my_logo'], width: 64, height: 64),
                    SizedBox(height: 4),
                    Text("선 ${data!['my_pitcher']}", style: TextStyle(color: Colors.blue)),
                  ],
                ),
                SizedBox(width: 16),
                Text("VS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(width: 16),
                Column(
                  children: [
                    Image.network(data!['opponent_logo'], width: 64, height: 64),
                    SizedBox(height: 4),
                    Text("선 ${data!['opponent_pitcher']}", style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            // 점수 또는 경기 상태
            isScheduled
                ? Text("경기예정", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                : Column(
                    children: [
                      Text('${data!['my_score']} : ${data!['opponent_score']}',
                          style: TextStyle(fontSize: 32)),
                      SizedBox(height: 8),
                      Text(data!['status'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
