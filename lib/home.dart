import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contacts.dart';
import 'location_sharing.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // FlutterLocalNotificationsPlugin instance
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  // Initialize notifications and request permissions for Android 13+
  void initializeNotifications() async {
    // Android-specific initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // General initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize the notifications plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permission manually for Android 13+
    await requestNotificationPermission();
  }

  // Function to request notification permissions
  Future<void> requestNotificationPermission() async {
    // Check if the permission is already granted
    if (await Permission.notification.isGranted) {
      print("Notification permission already granted.");
      return;
    }

    // Request permission if not granted
    PermissionStatus status = await Permission.notification.request();

    if (status.isGranted) {
      print("Notification permission granted.");
    } else if (status.isDenied) {
      print("Notification permission denied.");
    } else if (status.isPermanentlyDenied) {
      // Open app settings for the user to manually grant permission
      openAppSettings();
    }
  }

  // Function to show the notification
  Future<void> showNotification() async {
    // Notification details for Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'sos_channel', // Channel ID
      'SOS Notifications', // Channel Name
      channelDescription: 'Notification when SOS is triggered',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show notification
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'SOS Alert', // Notification title
      'Calling and messaging your contacts', // Notification body
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: const Color.fromARGB(255, 223, 218, 226),
            ),
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/watch.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                Flexible(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 193, 186, 222),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CONNECTED"),
                        Text("Battery Status: FULL"),
                        Text("GPS Tracking: ON"),
                        Text("Safety Status: YES"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(60),
                shape: const CircleBorder(),
              ),
              onPressed: () {
                // Show notification when SOS button is pressed
                showNotification();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Calling and messaging your contacts"),
                  ),
                );
              },
              child: const Text("SOS",
                  style: TextStyle(color: Colors.white, fontSize: 50)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactsManager(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.contacts),
                      label: const Text("Manage Contacts"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationSharing(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text("Location Sharing"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
