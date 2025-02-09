import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() => runApp(const CellTowerApp());

class CellTowerApp extends StatelessWidget {
  const CellTowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cell Tower Mapper',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SafeArea(child: CellTowerScreen()),
    );
  }
}

class CellTowerScreen extends StatefulWidget {
  const CellTowerScreen({super.key});

  @override
  State<CellTowerScreen> createState() => _CellTowerScreenState();
}

class _CellTowerScreenState extends State<CellTowerScreen> {
  final _mapControllerCompleter = Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  LatLng _currentLocation = const LatLng(0, 0);
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocationServices();
  }

  Future<void> _initializeLocationServices() async {
    try {
      await _verifyLocationPermissions();
      await _updateUserLocation();
      await _loadCellTowers();
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyLocationPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Enable location services');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Location permission required');
    }
  }

  Future<void> _updateUserLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(_createUserMarker(position));
    });
    
    final controller = await _mapControllerCompleter.future;
    controller.animateCamera(CameraUpdate.newLatLng(_currentLocation));
  }

  Marker _createUserMarker(Position position) {
    return Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  Future<void> _loadCellTowers() async {
    try {
      final towers = await CellTowerAPI.fetchNearbyTowers(
        _currentLocation.latitude,
        _currentLocation.longitude,
        'pk.254c218f3088c67c0bdb83fc083b1f0c',
      );

      setState(() {
        _markers.addAll(towers.map(_createTowerMarker));
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load towers: ${e.toString()}');
    }
  }

  Marker _createTowerMarker(Map<String, dynamic> tower) {
    return Marker(
      markerId: MarkerId('tower_${tower['id']}'),
      position: LatLng(tower['lat'], tower['lon']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(title: 'Tower ${tower['id']}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cell Tower Mapper')),
      body: _buildMapContent(),
    );
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      onMapCreated: (controller) => _mapControllerCompleter.complete(controller),
    );
  }
}

class CellTowerAPI {
  static Future<List<Map<String, dynamic>>> fetchNearbyTowers(
    double lat,
    double lon,
    String apiKey,
  ) async {
    final response = await http.get(Uri.parse(
      'https://us1.unwiredlabs.com/v2/process?token=$apiKey'
      '&radio=lte&mcc=310&mnc=260&cells=[{"lat":$lat,"lon":$lon}]'
    ));

    if (response.statusCode != 200) {
      throw Exception('API Error: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body);
    return (jsonData['cells'] as List).map((tower) => {
      'id': tower['cid'],
      'lat': tower['lat'],
      'lon': tower['lon'],
    }).toList();
  }
}