// community_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_service.dart'; // Import the location service
import 'nearby_users_service.dart'; // Import the nearby users service

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  Position? _currentPosition;
  List<DocumentSnapshot> _nearbyUsers = [];
  final LocationService _locationService =
      LocationService(); // Initialize location service
  final NearbyUsersService _nearbyUsersService =
      NearbyUsersService(); // Initialize nearby users service

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Fetch current GPS location and update it in Firebase
  Future<void> _getCurrentLocation() async {
    try {
      // Call the location service to update the location in Firestore
      await _locationService.updateUserLocation();

      // Fetch nearby users after updating the location
      await _fetchNearbyUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  // Define the _fetchNearbyUsers method
  Future<void> _fetchNearbyUsers() async {
    // Check if we have the current location
    if (_currentPosition != null) {
      // Call the NearbyUsersService to fetch users within a 50-meter radius
      List<DocumentSnapshot> users = await _nearbyUsersService.getNearbyUsers(
        currentLat: _currentPosition!.latitude,
        currentLng: _currentPosition!.longitude,
        radius: 50, // Radius in meters
      );

      // Update the state with the nearby users
      setState(() {
        _nearbyUsers = users;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Users'),
      ),
      body: _currentPosition == null
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator if no location yet
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Your current location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _nearbyUsers.isEmpty
                      ? const Center(child: Text('No users within 50 meters.'))
                      : ListView.builder(
                          itemCount: _nearbyUsers.length,
                          itemBuilder: (context, index) {
                            var user = _nearbyUsers[index];
                            return ListTile(
                              title: Text(user['email'] ?? 'Unknown'),
                              subtitle: Text(
                                'Location: (${user['location'].latitude}, ${user['location'].longitude})',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
