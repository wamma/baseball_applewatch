import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _widgetChannel = MethodChannel('com.example.baseball/widget');

const Map<String, String> kboTeams = {
  'LG 트윈스': 'assets/logos/lg.png',
  'SSG 랜더스': 'assets/logos/ssg.png',
  '삼성 라이온즈': 'assets/logos/samsung.png',
  '롯데 자이언츠': 'assets/logos/lotte.png',
  'NC 다이노스': 'assets/logos/nc.png',
  'KIA 타이거즈': 'assets/logos/kia.png',
  '키움 히어로즈': 'assets/logos/kiwoom.png',
  '한화 이글스': 'assets/logos/hanwha.png',
  '두산 베어스': 'assets/logos/bears.png',
  'KT 위즈': 'assets/logos/kt.png',
};

const Map<String, Color> kboTeamColors = {
  'LG 트윈스': Color(0xFFED1746),
  'SSG 랜더스': Color(0xFFCF0022),
  '삼성 라이온즈': Color(0xFF005BAC),
  '롯데 자이언츠': Color(0xFFD00F31),
  'NC 다이노스': Color(0xFF1E4790),
  'KIA 타이거즈': Color(0xFFD71718),
  '키움 히어로즈': Color(0xFF87001F),
  '한화 이글스': Color(0xFFEA5015),
  '두산 베어스': Color(0xFF0B1430),
  'KT 위즈': Color(0xFF000000),
};

class MyPageScreen extends StatefulWidget {
  final String? selectedTeam;
  final void Function(String?) onTeamSelected;

  const MyPageScreen({
    Key? key,
    this.selectedTeam,
    required this.onTeamSelected,
  }) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  Future<void> _selectTeam(String team) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myTeam', team);
    widget.onTeamSelected(team);
    // iOS 위젯 App Group에 팀 저장 → 위젯 자동 갱신
    try {
      await _widgetChannel.invokeMethod('saveTeam', team);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: const Center(
              child: Text(
                '마이페이지',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8E8E8)),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '마이팀을 선택해주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          // 팀 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: kboTeams.length,
              itemBuilder: (context, index) {
                final teamName = kboTeams.keys.elementAt(index);
                final logoPath = kboTeams[teamName]!;
                final isSelected = teamName == widget.selectedTeam;
                return _buildTeamItem(teamName, logoPath, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem(
      String teamName, String logoPath, bool isSelected) {
    final teamColor = kboTeamColors[teamName] ?? const Color(0xFF2196F2);
    return GestureDetector(
      onTap: () => _selectTeam(teamName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? teamColor.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? teamColor : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logoPath,
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                  Icons.sports_baseball,
                  size: 56,
                  color: Colors.grey[300]),
            ),
            const SizedBox(height: 8),
            Text(
              teamName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? teamColor : const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
