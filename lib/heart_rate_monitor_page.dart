// ignore_for_file: use_super_parameters

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
  int? _heartRate;

  @override
  void initState() {
    super.initState();
    _connectToDevice(widget.device);
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    _ble.connectToDevice(id: device.id).listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        _discoverServices();
      }
    }, onError: (error) {
      print('Connection error: $error');
    });
  }

  Future<void> _discoverServices() async {
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
  }

  void _startHeartRateMonitoring() {
    _heartRateSubscription =
        _ble.subscribeToCharacteristic(_heartRateCharacteristic).listen((data) {
      setState(() {
        _heartRate = data[1]; // Assuming second byte contains heart rate data
      });
    }, onError: (error) {
      print('Heart rate subscription error: $error');
    });
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
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
          Column(
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
                      color: Colors.black,
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
          ),
        ],
      ),
    );
  }
}
