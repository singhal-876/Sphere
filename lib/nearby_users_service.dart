// nearby_users_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class NearbyUsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch users from Firestore within a given radius
  Future<List<DocumentSnapshot>> getNearbyUsers({
    required double currentLat,
    required double currentLng,
    required double radius,
  }) async {
    // Fetch all users from Firestore
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    List<DocumentSnapshot> nearbyUsers = [];

    for (var doc in snapshot.docs) {
      GeoPoint userLocation = doc['location'];

      // Calculate distance between the current user and the other users
      double distance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        userLocation.latitude,
        userLocation.longitude,
      );

      // Check if the user is within the specified radius
      if (distance <= radius) {
        nearbyUsers.add(doc);
      }
    }

    return nearbyUsers;
  }
}
