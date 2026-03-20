// 이 파일은 레거시 파일입니다.
// 팀 선택은 이제 MyPageScreen에서 직접 처리됩니다.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, String> kboTeamsLegacy = {
  'LG 트윈스': 'assets/logos/lg.png',
  'KT 위즈': 'assets/logos/kt.png',
  'SSG 랜더스': 'assets/logos/ssg.png',
  'NC 다이노스': 'assets/logos/nc.png',
  'KIA 타이거즈': 'assets/logos/kia.png',
  '두산 베어스': 'assets/logos/bears.png',
  '롯데 자이언츠': 'assets/logos/lotte.png',
  '삼성 라이온즈': 'assets/logos/samsung.png',
  '한화 이글스': 'assets/logos/hanwha.png',
  '키움 히어로즈': 'assets/logos/kiwoom.png',
};

class TeamSelectionPage extends StatefulWidget {
  @override
  _TeamSelectionPageState createState() => _TeamSelectionPageState();
}

class _TeamSelectionPageState extends State<TeamSelectionPage> {
  String? selectedTeam;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTeam = prefs.getString('myTeam');
    });
  }

  Future<void> _saveTeam(String team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myTeam', team);
    setState(() => selectedTeam = team);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이팀 설정')),
      body: ListView.builder(
        itemCount: kboTeamsLegacy.length,
        itemBuilder: (context, index) {
          final team = kboTeamsLegacy.keys.elementAt(index);
          final isSelected = team == selectedTeam;
          return ListTile(
            title: Text(team),
            leading: Image.asset(kboTeamsLegacy[team]!,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.sports_baseball)),
            trailing: isSelected
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => _saveTeam(team),
          );
        },
      ),
      floatingActionButton: selectedTeam != null
          ? FloatingActionButton.extended(
              label: const Text('완료'),
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context),
            )
          : null,
    );
  }
}
