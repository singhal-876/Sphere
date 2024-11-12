import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class GoogleKmlMapPage extends StatefulWidget {
  @override
  _GoogleKmlMapPageState createState() => _GoogleKmlMapPageState();
}

class _GoogleKmlMapPageState extends State<GoogleKmlMapPage> {
  late GoogleMapController mapController;
  final Set<Marker> markers = {};

  Future<void> _loadKml() async {
    final kmlString = await rootBundle.loadString('assets/doc.kml');
    final kmlDocument = xml.XmlDocument.parse(kmlString);

    for (var placemark in kmlDocument.findAllElements('Placemark')) {
      final coordinates =
          placemark.findElements('coordinates').first.text.trim().split(',');
      final lat = double.parse(coordinates[1]);
      final lng = double.parse(coordinates[0]);

      markers.add(
        Marker(
          markerId: MarkerId(lat.toString() + lng.toString()),
          position: LatLng(lat, lng),
        ),
      );
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadKml();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("KML in Google Maps")),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: markers,
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 5,
        ),
      ),
    );
  }
}
