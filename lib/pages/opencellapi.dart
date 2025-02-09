import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CellTowerMap extends StatefulWidget {
  const CellTowerMap({super.key});

  @override
  CellTowerMapState createState() => CellTowerMapState();
}

class CellTowerMapState extends State<CellTowerMap> {
  final Map<String, dynamic> _config = {
    'apiKey': 'pk.254c218f3088c67c0bdb83fc083b1f0c',
    'apiEndpoint': 'https://us1.unwiredlabs.com/v2/process',
  };

  late GoogleMapController _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocationServices();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationServices() async {
    try {
      await _checkLocationPermissions();
      await _getCurrentLocation();
      await _fetchCellTowers();
    } catch (e) {
      _showErrorSnackbar('Location services error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission != LocationPermission.always && 
        permission != LocationPermission.whileInUse) {
      throw Exception('Location permissions denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(_createUserMarker(position));
    });
    _mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
  }

  Marker _createUserMarker(Position position) {
    return Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  Future<void> _fetchCellTowers() async {
    try {
      final towers = await CellTowerService.fetchTowers(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _config['apiKey'],
      );

      setState(() {
        _markers.addAll(towers.map(_createTowerMarker));
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load cell towers: ${e.toString()}');
    }
  }

  Marker _createTowerMarker(Map<String, dynamic> tower) {
    return Marker(
      markerId: MarkerId('tower_${tower['cid']}'),
      position: LatLng(tower['lat'], tower['lon']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(title: 'Cell Tower ID: ${tower['cid']}'),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cell Tower Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _markers,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
            ),
    );
  }
}

class CellTowerService {
  static Future<List<Map<String, dynamic>>> fetchTowers(
    double lat,
    double lon,
    String apiKey,
  ) async {
    final response = await http.get(Uri.parse(
      'https://us1.unwiredlabs.com/v2/process?token=$apiKey'
      '&radio=lte&mcc=310&mnc=260&cells=[{"lat":$lat,"lon":$lon}]'
    ));

    if (response.statusCode != 200) {
      throw Exception('API request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return (data['cells'] as List).map((cell) => {
      'lat': cell['lat'],
      'lon': cell['lon'],
      'cid': cell['cid'],
    }).toList();
  }
}