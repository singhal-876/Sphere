import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSharing extends StatefulWidget {
  const LocationSharing({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LocationSharingState createState() => _LocationSharingState();
}

class _LocationSharingState extends State<LocationSharing> {
  bool _isSharing = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadSharingStatus();
  }

  _loadSharingStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSharing = prefs.getBool('isSharing') ?? false;
    });
    if (_isSharing) {
      _startLocationUpdates();
    }
  }

  _saveSharingStatus(bool isSharing) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSharing', isSharing);
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
      // Here you would typically send the position to your server or perform other actions
      // ignore: avoid_print
      print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    });
  }

  void _stopLocationUpdates() {
    // Stop the location stream
    // In a real app, you'd also want to cancel any background location tracking
    setState(() {
      _currentPosition = null;
    });
  }

  void _toggleSharing() {
    setState(() {
      _isSharing = !_isSharing;
    });
    _saveSharingStatus(_isSharing);
    if (_isSharing) {
      _startLocationUpdates();
    } else {
      _stopLocationUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _isSharing ? 'Sharing Location' : 'Not Sharing Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            if (_currentPosition != null)
              Text(
                'Current Location:\nLat: ${_currentPosition!.latitude}\nLong: ${_currentPosition!.longitude}',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleSharing,
              child: Text(_isSharing ? 'Stop Sharing' : 'Start Sharing'),
            ),
          ],
        ),
      ),
    );
  }
}
