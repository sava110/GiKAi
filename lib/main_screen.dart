import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'subject_info_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // 初期選択はマップ（インデックス1）

  // 表示する画面のリスト
  final List<Widget> _screens = [
    const HomeScreen(),        // ホーム画面
    const MapScreen(),     // マップ画面（既存）
    const SubjectInfoScreen(), // 科目情報画面
    const SettingsScreen(),    // 設定画面
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'マップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '科目情報',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}