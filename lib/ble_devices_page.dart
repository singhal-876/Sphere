import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';
import 'heart_rate_monitor_page.dart'; // Import updated heart rate monitor page

class BLEDevicesPage extends StatefulWidget {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HeartRateMonitorPage(
            device: device), // Navigate to the updated HeartRateMonitorPage
      ),
    );
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
            onTap: () => _connectToDevice(
                _devicesList[index]), // Connect to selected device
          );
        },
      ),
    );
  }
}
