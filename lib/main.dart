import 'package:flutter/material.dart';
import 'ble_device_page.dart'; // Import BLE device page for heart rate monitor
import 'home.dart';
import 'bottom_nav_bar.dart'; // Assuming you have a separate file for community
import 'location_sharing.dart'; // Assuming you have a separate file for location sharing

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Sphere",
    home: const HomePage(),
    theme: ThemeData(
      primaryColor: const Color.fromARGB(255, 247, 244, 233),
      scaffoldBackgroundColor: const Color.fromARGB(255, 247, 244, 233),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 223, 218, 226),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
      ),
    ),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedItem = 0;

  final List<Widget> pages = [
    const Home(),
    const Community(),
    const LocationSharing(),
    const BLEDevicesPage(), // Heart Rate via BLE Devices
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sphere"),
      ),
      drawer: const DrawerMenu(),
      body: pages[selectedItem],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.pink[100],
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.pink[200],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: "Location"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Heart Rate"),
        ],
        currentIndex: selectedItem,
        onTap: (value) {
          setState(() {
            selectedItem = value;
          });
        },
      ),
    );
  }
}

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_drawer_img.png'),
                fit: BoxFit.cover,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage('assets/images/sphere.png'),
            ),
            accountName: Text(
              "Sphere_username_1",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              "username1@gmail.com",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
          ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('Contact'),
          ),
        ],
      ),
    );
  }
}
