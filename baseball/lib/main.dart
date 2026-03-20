import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './screens/all_games_page.dart';
import './screens/team_status_page.dart';
import './screens/my_page_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My KBO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2196F2),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        fontFamily: 'Pretendard',
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  String? _myTeam;

  @override
  void initState() {
    super.initState();
    _loadMyTeam();
  }

  Future<void> _loadMyTeam() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myTeam = prefs.getString('myTeam');
    });
  }

  void _onTeamSelected(String? team) {
    setState(() {
      _myTeam = team;
    });
  }

  void _goToMyPageTab() {
    setState(() {
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TeamStatusPage(
            key: ValueKey(_myTeam),
            myTeam: _myTeam,
            onChangeTeam: _goToMyPageTab,
          ),
          AllGamesPage(),
          MyPageScreen(
            selectedTeam: _myTeam,
            onTeamSelected: _onTeamSelected,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2196F2),
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: '마이팀',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_baseball_outlined),
            activeIcon: Icon(Icons.sports_baseball),
            label: '전체경기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}
