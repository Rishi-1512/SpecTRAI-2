import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'map_page.dart';
import 'preset_page.dart';
import 'settings_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    MapPage(),
    PresetPage(),
    SettingsPage(),
  ];

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Image.asset('lib/image/namebw.png', height: 35),
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          color: Color(0xFFFEEDDF),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
            child: GNav(
              backgroundColor: Color(0xFFFEEDDF),
              color: Colors.black,
              activeColor: Colors.black,
              tabBackgroundColor: Colors.grey.shade300,
              gap: 8,
              padding: EdgeInsets.all(16),
              selectedIndex: _selectedIndex,
              onTabChange: _onNavBarTapped,
              tabs: const [
                GButton(icon: Icons.home, text: 'Home'),
                GButton(icon: Icons.map, text: 'Maps'),
                GButton(icon: Icons.layers, text: 'Presets'),
                GButton(icon: Icons.settings, text: 'Settings'),
              ],
            ),
          ),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String downloadSpeed = "---";
  String uploadSpeed = "---";
  String ping = "---";
  bool isLoading = false;

  /// Fetch speed test results from Flask API
  Future<void> fetchSpeedTestResults() async {
    setState(() => isLoading = true);

    final url = Uri.parse("http://10.0.2.2:5000/speedtest"); // Emulator URL

    try {
      final response = await http.get(url);

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        downloadSpeed = "${data['download_speed']} Mbps";
        uploadSpeed = "${data['upload_speed']} Mbps";
        ping = "${data['ping']} ms";
      } else {
        print("Failed to fetch data. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 10),
          Image.asset('lib/image/towergif.gif', width: 400, height: 300),
          SizedBox(height: 30),
          BandDataWidget(),
          SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Optimize it for",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 10),
                OptimizeDropdown(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : fetchSpeedTestResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF899499),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Calculate",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          BandStatsWidget(downloadSpeed, uploadSpeed, ping),
        ],
      ),
    );
  }
}

// ✅ Additional Widgets

class BandDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Band Data",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 10),
        Text(
          "Data related to your network band will be displayed here.",
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}

class OptimizeDropdown extends StatefulWidget {
  @override
  _OptimizeDropdownState createState() => _OptimizeDropdownState();
}

class _OptimizeDropdownState extends State<OptimizeDropdown> {
  String _selectedOption = "Default";

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedOption,
      dropdownColor: Colors.black,
      style: TextStyle(color: Colors.white, fontSize: 16),
      iconEnabledColor: Colors.white,
      onChanged: (String? newValue) {
        setState(() {
          _selectedOption = newValue!;
        });
      },
      items: <String>["Default", "Gaming", "Streaming", "Browsing"]
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }
}

class BandStatsWidget extends StatelessWidget {
  final String download;
  final String upload;
  final String ping;

  BandStatsWidget(this.download, this.upload, this.ping);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Download: $download", style: TextStyle(color: Colors.white)),
        Text("Upload: $upload", style: TextStyle(color: Colors.white)),
        Text("Ping: $ping", style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
