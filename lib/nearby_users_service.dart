import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'integrated_location_service.dart';

class NearbyUsersPage extends StatefulWidget {
  const NearbyUsersPage({super.key});

  @override
  _NearbyUsersPageState createState() => _NearbyUsersPageState();
}

class _NearbyUsersPageState extends State<NearbyUsersPage> {
  final IntegratedLocationService _locationService =
      IntegratedLocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userEmail;
  List<Map<String, dynamic>> nearbyUsers = [];
  bool _isSharing = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    await _locationService.initialize();
    setState(() {
      _isSharing = _locationService.isSharing;
    });
    _getCurrentPositionAndFetchUsers();
  }

  Future<void> _getCurrentPositionAndFetchUsers() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      await _getUserEmail();
      await _getNearbyUsers();
    } catch (e) {
      print('Error getting current position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    }
  }

  Future<void> _getUserEmail() async {
    final user = _auth.currentUser;
    setState(() {
      userEmail = user?.email;
    });
  }

  Future<void> _getNearbyUsers() async {
    if (_auth.currentUser == null) {
      print('User is not authenticated');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to see nearby users')),
      );
      return;
    }

    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();

      List<Map<String, dynamic>> users = querySnapshot.docs
          .where((doc) => doc.id != _auth.currentUser?.uid)
          .map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).where((user) {
        GeoPoint? userLocation = user['location'] as GeoPoint?;
        if (userLocation == null) return false;

        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          userLocation.latitude,
          userLocation.longitude,
        );
        return distance <= 50; // 50 meters radius
      }).toList();

      setState(() {
        nearbyUsers = users;
      });
    } catch (e) {
      print('Error getting nearby users: $e');
      String errorMessage = 'Failed to get nearby users';
      if (e is FirebaseException && e.code == 'permission-denied') {
        errorMessage +=
            ': Permission denied. Please check Firestore security rules.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _toggleSharing() async {
    try {
      await _locationService.toggleSharing();
      setState(() {
        _isSharing = _locationService.isSharing;
      });
      await _getCurrentPositionAndFetchUsers();
    } catch (e) {
      print('Error toggling location sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle location sharing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Users'),
        actions: [
          IconButton(
            icon: Icon(_isSharing ? Icons.location_on : Icons.location_off),
            onPressed: _toggleSharing,
          ),
        ],
      ),
      body: Column(
        children: [
          Text('Your email: ${userEmail ?? 'Loading...'}'),
          Text(_isSharing ? 'Sharing Location' : 'Not Sharing Location'),
          Text('Nearby Users: ${nearbyUsers.length}'),
          Expanded(
            child: ListView.builder(
              itemCount: nearbyUsers.length,
              itemBuilder: (context, index) {
                final user = nearbyUsers[index];
                return ListTile(
                  title: Text(user['email'] ?? 'No email'),
                  subtitle: Text('ID: ${user['id']}'),
                  trailing: Text(
                      'Last updated: ${_formatTimestamp(user['lastUpdated'])}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentPositionAndFetchUsers,
        tooltip: 'Refresh Nearby Users',
        child: Icon(Icons.refresh),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return timestamp.toDate().toString();
    }
    return timestamp.toString();
  }
}
