// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async'; // Import for StreamSubscription

class BLEDevicesPage extends StatefulWidget {
  const BLEDevicesPage({super.key});

  @override
  _BLEDevicesPageState createState() => _BLEDevicesPageState();
}

class _BLEDevicesPageState extends State<BLEDevicesPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  late StreamSubscription<DiscoveredDevice> _scanSubscription;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      setState(() {
        if (!_devicesList.contains(device)) {
          _devicesList.add(device);
        }
      });
    }, onError: (error) {
      print('Scan error: $error');
    });
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    super.dispose();
  }

  void _connectToDevice(DiscoveredDevice device) async {
    final connection =
        _ble.connectToDevice(id: device.id).listen((connectionState) {
      print('Connection state: $connectionState');
    }, onError: (error) {
      print('Connection error: $error');
    });

    // Example wait before disconnecting or doing further work
    await Future.delayed(const Duration(seconds: 5));
    connection.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available BLE Devices'),
      ),
      body: ListView.builder(
        itemCount: _devicesList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_devicesList[index].name.isNotEmpty
                ? _devicesList[index].name
                : "Unnamed Device"),
            subtitle: Text(_devicesList[index].id),
            onTap: () => _connectToDevice(_devicesList[index]),
          );
        },
      ),
    );
  }
}
