import 'package:flutter/material.dart';
import 'my_page_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My KBO Team',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyPageScreen(),  // 첫 화면을 마이페이지로
    );
  }
}
