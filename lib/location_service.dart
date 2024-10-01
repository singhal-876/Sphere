// location_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to update the user's live location in Firestore
  Future<void> updateUserLocation() async {
    try {
      // Request location permissions if necessary
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permissions are denied');
        return;
      }

      // Fetch the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Current location: ${position.latitude}, ${position.longitude}");

      // Get the current user ID from Firebase Authentication
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Update Firestore with the new location
      await _firestore.collection('users').doc(userId).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Location updated successfully in Firestore');
    } catch (e) {
      print('Error updating location: $e');
    }
  }
}
