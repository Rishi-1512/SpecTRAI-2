import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'map_page.dart';
import 'preset_page.dart';
import 'settings_page.dart';

class BandStatsWidget extends StatelessWidget {
  final String download, upload, ping, signalStrength, earfcn;

  BandStatsWidget(
      this.download, this.upload, this.ping, this.signalStrength, this.earfcn);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Download: $download", style: TextStyle(color: Colors.white)),
        Text("Upload: $upload", style: TextStyle(color: Colors.white)),
        Text("Ping: $ping", style: TextStyle(color: Colors.white)),
        Text("Signal Strength: $signalStrength",
            style: TextStyle(color: Colors.white)),
        Text("EARFCN: $earfcn", style: TextStyle(color: Colors.white)),
      ],
    );
  }
}

class BandDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Band Data", style: TextStyle(color: Colors.white, fontSize: 20)),
        // Add your band-related widgets here
      ],
    );
  }
}

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
      backgroundColor: Colors.black, // ✅ Fix for white UI issue
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
  String signalStrength = "---";
  String earfcn = "---";
  bool isLoading = false;
  String _selectedOption = "Download (For YouTube & Twitch)";

  static const platform = MethodChannel('com.example.signal/info');

  Future<void> fetchSpeedTestResults() async {
    setState(() => isLoading = true);
    final url = Uri.parse("http://10.0.2.2:5000/speedtest");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          downloadSpeed = "${data['download_speed']} Mbps";
          uploadSpeed = "${data['upload_speed']} Mbps";
          ping = "${data['ping']} ms";
        });

        await fetchAndStoreNetworkDetails();
      } else {
        print("Failed to fetch data. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchAndStoreNetworkDetails() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      print("Phone permission denied");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      final Map<dynamic, dynamic>? data =
          await platform.invokeMethod('getSignalInfo');

      if (data != null) {
        final Map<String, dynamic> networkData = {
          "mode": getSelectedMode(),
          "longitude": position.longitude,
          "latitude": position.latitude,
          "rsrp": data['rsrp'] ?? "---",
          "rsrq": data['rsrq'] ?? "---",
          "earfcn": data['earfcn'] ?? "---",
          "signal_strength": data['dbm'] ?? "---",
          "bandwidth": data['bandwidth'] ?? "---",
          "pci": data['pci'] ?? "---"
        };

        setState(() {
          signalStrength = "${data['dbm'] ?? "---"} dBm";
          earfcn = data['earfcn']?.toString() ?? "---";
        });

        DatabaseReference ref = FirebaseDatabase.instance
            .ref("network_data/${DateTime.now().millisecondsSinceEpoch}");
        await ref.set(networkData);
      }
    } catch (e) {
      print("Error getting signal info: $e");
    }
  }

  String getSelectedMode() {
    switch (_selectedOption) {
      case "Download (For YouTube & Twitch)":
        return "1";
      case "Upload (For Video Calls & Live Streaming)":
        return "2";
      case "Ping (For Gaming)":
        return "3";
      default:
        return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // ✅ Fix for white UI issue
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
                Text("Optimize it for",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: _selectedOption,
                  dropdownColor: Colors.black,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  iconEnabledColor: Colors.white,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedOption = newValue!;
                    });
                  },
                  items: [
                    "Download (For YouTube & Twitch)",
                    "Upload (For Video Calls & Live Streaming)",
                    "Ping (For Gaming)"
                  ]
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : fetchSpeedTestResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF899499),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Calculate",
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          BandStatsWidget(
              downloadSpeed,
              uploadSpeed,
              ping,
              signalStrength, // ✅ Updated SS
              earfcn // ✅ Updated EARFCN
              ),
        ],
      ),
    );
  }
}
