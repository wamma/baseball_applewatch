import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      final encoded = Uri.encodeComponent(widget.teamName);
      final url = 'https://riverside-commander-levy-majority.trycloudflare.com/score?team=$encoded';
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
      return Scaffold(
        appBar: AppBar(title: Text('오류')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("오류: $error"),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchScore,
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text('로딩 중...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (data!.containsKey('error')) {
      return Scaffold(
        appBar: AppBar(title: Text('오류')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data!['error']),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchScore,
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final isScheduled = data!['status'] == '경기예정';

    return Scaffold(
      appBar: AppBar(title: Text('${data!['my_team']} 경기 정보')),
      body: RefreshIndicator(
        onRefresh: fetchScore,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              child: data!['my_logo'].isNotEmpty 
                                  ? Image.network(data!['my_logo'], width: 80, height: 80, errorBuilder: (_, __, ___) => Icon(Icons.sports_baseball, size: 80))
                                  : Icon(Icons.sports_baseball, size: 80),
                            ),
                            SizedBox(height: 8),
                            Text(data!['my_team'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text("선발: ${data!['my_pitcher']}", style: TextStyle(color: Colors.blue, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("VS", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              child: data!['opponent_logo'].isNotEmpty 
                                  ? Image.network(data!['opponent_logo'], width: 80, height: 80, errorBuilder: (_, __, ___) => Icon(Icons.sports_baseball, size: 80))
                                  : Icon(Icons.sports_baseball, size: 80),
                            ),
                            SizedBox(height: 8),
                            Text(data!['opponent'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text("선발: ${data!['opponent_pitcher']}", style: TextStyle(color: Colors.blue, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  if (isScheduled)
                    Text("경기예정", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                  else if (data!.containsKey('my_score') && data!.containsKey('opponent_score'))
                    Column(
                      children: [
                        Text('${data!['my_score']} : ${data!['opponent_score']}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: data!['status'] == '승리' ? Colors.blue.withOpacity(0.1)
                              : data!['status'] == '패배' ? Colors.red.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            data!['status'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: data!['status'] == '승리' ? Colors.blue
                                : data!['status'] == '패배' ? Colors.red
                                : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(data!['status'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchScore,
        child: Icon(Icons.refresh),
        tooltip: '새로고침',
      ),
    );
  }
}
