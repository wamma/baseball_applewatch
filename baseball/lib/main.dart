import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  '한화 이글스': 'assets/logos/hanwha.jpg',
  '키움 히어로즈': 'assets/logos/kia.png',
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
      appBar: AppBar(
        title: Text('마이팀 설정'),
      ),
      body: ListView.builder(
        itemCount: kboTeams.length,
        itemBuilder: (context, index) {
          final team = kboTeams.keys.elementAt(index);
          final isSelected = team == selectedTeam;
          return ListTile(
            title: Text(''),
            leading: Image.asset(kboTeams[team]!),
            trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
            onTap: () => saveTeam(team),
          );
        },
      ),
    );
  }
}
