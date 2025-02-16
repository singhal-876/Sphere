import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class HeartRateMonitorPage extends StatefulWidget {
  final DiscoveredDevice device;

  const HeartRateMonitorPage({Key? key, required this.device})
      : super(key: key);

  @override
  _HeartRateMonitorPageState createState() => _HeartRateMonitorPageState();
}

class _HeartRateMonitorPageState extends State<HeartRateMonitorPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late QualifiedCharacteristic _heartRateCharacteristic;
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  int? _heartRate;
  bool _isConnected = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectToDevice(widget.device);
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    _connectionSubscription = _ble.connectToDevice(id: device.id).listen(
      (connectionState) {
        if (connectionState.connectionState ==
            DeviceConnectionState.connected) {
          setState(() {
            _isConnected = true;
            _isLoading = false;
          });
          _discoverServices();
        } else if (connectionState.connectionState ==
            DeviceConnectionState.disconnected) {
          setState(() {
            _isConnected = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Connection failed: $error');
      },
    );
  }

  Future<void> _discoverServices() async {
    try {
      final services = await _ble.discoverServices(widget.device.id);
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.characteristicId ==
              Uuid.parse("00002a37-0000-1000-8000-00805f9b34fb")) {
            _heartRateCharacteristic = QualifiedCharacteristic(
              serviceId: service.serviceId,
              characteristicId: characteristic.characteristicId,
              deviceId: widget.device.id,
            );
            _startHeartRateMonitoring();
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to discover services: $e');
    }
  }

  void _startHeartRateMonitoring() {
    _heartRateSubscription =
        _ble.subscribeToCharacteristic(_heartRateCharacteristic).listen(
      (data) {
        if (data.isNotEmpty) {
          setState(() {
            _heartRate = data[1]; // Assuming second byte contains heart rate
          });
        }
      },
      onError: (error) {
        _showErrorDialog('Heart rate subscription error: $error');
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/mountain.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : _isConnected
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Your Stats',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Heart Rate',
                            style: TextStyle(
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _heartRate != null
                                      ? '$_heartRate bpm'
                                      : 'Waiting for data...',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '*Above 100 bpm emergency call will activate',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple[200],
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Device not connected.',
                        style: TextStyle(fontSize: 18),
                      ),
          ),
        ],
      ),
    );
  }
}
