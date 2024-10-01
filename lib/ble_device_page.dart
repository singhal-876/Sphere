// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

import 'package:sphere/heart_rate_monitor_page.dart'; // Import for StreamSubscription

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

  void _connectToDevice(DiscoveredDevice device) {
    final connectionStream = _ble.connectToDevice(id: device.id);

    connectionStream.listen((connectionState) {
      print('Connection state: $connectionState');

      if (connectionState.connectionState == DeviceConnectionState.connected) {
        // Navigate to the heart rate monitor page when the device is successfully connected
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HeartRateMonitorPage(device: device),
          ),
        );
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        // Handle disconnection if necessary
        print('Device disconnected');
      }
    }, onError: (error) {
      // Handle connection error
      print('Connection error: $error');
    });
  }

  // Example wait before disconnecting or doing further work
  //   await Future.delayed(Duration(seconds: 5));
  //   connection.cancel();
  // }

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
