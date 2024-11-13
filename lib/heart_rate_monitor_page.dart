import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class HeartRateMonitorPage extends StatefulWidget {
  final DiscoveredDevice device;

  const HeartRateMonitorPage({super.key, required this.device});

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
  bool _isMonitoring = false;
  Timer? _threatCheckTimer;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    setState(() => _isConnected = false);

    _connectionSubscription = _ble
        .connectToDevice(
      id: widget.device.id,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen((connectionState) {
      setState(() {
        _isConnected =
            connectionState.connectionState == DeviceConnectionState.connected;
      });

      if (_isConnected) {
        _discoverServices();
      }
    }, onError: (error) {
      print('Connection error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $error')),
      );
    });
  }

  Future<void> _discoverServices() async {
    try {
      final services = await _ble.discoverServices(widget.device.id);
      for (var service in services) {
        // Replace with your ESP32's actual service and characteristic UUIDs
        if (service.serviceId ==
            Uuid.parse("12345678-1234-1234-1234-123456789012")) {
          for (var characteristic in service.characteristics) {
            if (characteristic.characteristicId ==
                Uuid.parse("abcd1234-ab12-cd34-ef56-abcdef123456")) {
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
    } catch (e) {
      print('Service discovery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service discovery error: $e')),
      );
    }
  }

  void _startHeartRateMonitoring() {
    setState(() => _isMonitoring = true);

    _heartRateSubscription =
        _ble.subscribeToCharacteristic(_heartRateCharacteristic).listen(
      (data) {
        final heartRate = data[1]; // Adjust based on your ESP32's data format
        setState(() => _heartRate = heartRate);

        // if (heartRate > 100) {
        //   _checkForThreat();
        // }
      },
      onError: (error) {
        print('Heart rate subscription error: $error');
        setState(() => _isMonitoring = false);
      },
    );

    // // Start periodic threat detection
    // _threatCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   if (_heartRate != null) {
    //     _checkForThreat();
    //   }
    // });
  }

  // void _checkForThreat() {
  //   if (_heartRate != null) {
  //     // Sample voice data - replace with actual implementation
  //     List<int> voiceData = [1, 2, 3, 4, 5];

  //     bool threatDetected = ThreatDetection.isThreatDetected(
  //       _heartRate!,
  //       voiceData,
  //     );

  //     if (threatDetected) {
  //       ThreatDetection.triggerEmergencyCall(context);
  //     }
  //   }
  // }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _threatCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Monitor'),
      ),
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
              if (!_isConnected)
                const CircularProgressIndicator()
              else if (!_isMonitoring)
                const Text('Starting monitoring...')
              else
                Column(
                  children: [
                    const Text(
                      'Heart Rate',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _heartRate != null && _heartRate! > 100
                            ? Colors.red[100]
                            : Colors.purple[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: _heartRate != null && _heartRate! > 100
                                ? Colors.red
                                : Colors.black,
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
                  ],
                ),
              const SizedBox(height: 20),
              Text(
                '*Above 100 bpm emergency call will activate',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple[200],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
