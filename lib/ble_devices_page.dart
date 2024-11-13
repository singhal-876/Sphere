import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'heart_rate_monitor_page.dart';

class BleScannerPage extends StatefulWidget {
  const BleScannerPage({super.key});

  @override
  _BleScannerPageState createState() => _BleScannerPageState();
}

class _BleScannerPageState extends State<BleScannerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() {
    setState(() {
      _devices = [];
      _isScanning = true;
    });

    _ble.scanForDevices(
      withServices: [
        Uuid.parse("12345678-1234-1234-1234-123456789012")
      ], // Add your ESP32 service UUID if known
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (!_devices.any((d) => d.id == device.id)) {
        setState(() {
          _devices.add(device);
        });
      }
    }, onError: (error) {
      print('Scanning error: $error');
      setState(() {
        _isScanning = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Device'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isScanning ? 'Scanning for devices...' : 'Available devices:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(
                      device.name.isEmpty ? 'Unknown Device' : device.name),
                  subtitle: Text(device.id),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HeartRateMonitorPage(device: device),
                        ),
                      );
                    },
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScanning,
        child: Icon(_isScanning ? Icons.stop : Icons.refresh),
      ),
    );
  }
}
