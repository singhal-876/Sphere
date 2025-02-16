import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class BLEDevicesPage extends StatefulWidget {
  const BLEDevicesPage({super.key});

  @override
  _BLEDevicesPageState createState() => _BLEDevicesPageState();
}

class _BLEDevicesPageState extends State<BLEDevicesPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  late StreamSubscription<DiscoveredDevice> _scanSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });

    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      setState(() {
        if (!_devicesList.any((d) => d.id == device.id)) {
          _devicesList.add(device);
        }
      });
    }, onError: (error) {
      print('Scan error: $error');
      setState(() {
        _isScanning = false;
      });
    }, onDone: () {
      setState(() {
        _isScanning = false;
      });
    });
  }

  void _stopScan() {
    _scanSubscription.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    super.dispose();
  }

  void _selectDevice(DiscoveredDevice device) {
    Navigator.pop(context, device); // Return the selected device to the home page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available BLE Devices'),
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopScan,
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _devicesList.isEmpty
          ? const Center(child: Text('No devices found. Scanning...'))
          : ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _devicesList[index].name.isNotEmpty
                        ? _devicesList[index].name
                        : "Unnamed Device",
                  ),
                  subtitle: Text(_devicesList[index].id),
                  onTap: () => _selectDevice(
                      _devicesList[index]), // Return the selected device
                );
              },
            ),
    );
  }
}
