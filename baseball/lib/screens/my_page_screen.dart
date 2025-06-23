import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'team_selection_page.dart';
import 'team_status_page.dart';
import 'all_games_page.dart';


class MyPageScreen extends StatefulWidget {
  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? myTeam;

  @override
  void initState() {
    super.initState();
    loadMyTeam();
  }

  Future<void> loadMyTeam() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myTeam = prefs.getString('myTeam');
    });
  }

  void navigateToTeamSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamSelectionPage()),
    );
    loadMyTeam(); // 변경 후 다시 불러오기
  }

  void goToTeamStatus() {
    if (myTeam != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamStatusPage(teamName: myTeam!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("마이페이지")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              myTeam != null ? "현재 마이팀: $myTeam" : "마이팀이 설정되지 않았습니다.",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: navigateToTeamSelection,
              icon: Icon(Icons.edit),
              label: Text("마이팀 변경하기"),
            ),
            if (myTeam != null) ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: goToTeamStatus,
                icon: Icon(Icons.sports_baseball),
                label: Text("현재 경기 보기"),
              ),
            ],
              SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AllGamesPage()),
                );
              },
              icon: Icon(Icons.list),
              label: Text("전체 경기 보기"),
            ),
          ],
        ),
      ),
    );
  }

}