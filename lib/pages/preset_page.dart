import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'settings_page.dart';

class PresetPage extends StatefulWidget {
  @override
  _PresetPageState createState() => _PresetPageState();
}

class _PresetPageState extends State<PresetPage> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    HomePage(),
    MapPage(),
    PresetPage(),
    SettingsPage(),
  ];

  void _onNavBarTap(int index) {
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _pages[index]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Presets Page")),
    );
  }
}
